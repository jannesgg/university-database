CREATE OR REPLACE FUNCTION unregister_check()
RETURNS trigger
  AS $$
  BEGIN
    -- CHECK IF REGISTERED AND NOT ON WAITING LIST --
    IF (SELECT COUNT(*)
            FROM Registrations 
            WHERE national_id = OLD.national_id AND code = OLD.code
            AND waiting_status = 'registered') > 0 AND 
       (SELECT COUNT(a.code)
            FROM (
              SELECT code, COUNT(*) AS total_registered FROM Registrations
              WHERE waiting_status = 'registered'
              GROUP BY code ) AS a
            LEFT JOIN Restricted_course AS b
            ON a.code = b.code
            WHERE a.total_registered = b.max_students 
            AND a.code = OLD.code) > 0
      THEN
        DELETE FROM Waiting_list
        WHERE national_id = OLD.national_id
        AND code = OLD.code; 
        DELETE FROM Registers
        WHERE national_id = OLD.national_id 
        AND code = OLD.code; 
        INSERT INTO Registers(national_id, code)
          SELECT national_id, code FROM CourseQueuePositions
        WHERE code = OLD.code AND place_in_queue = 1;
        
    ELSIF (SELECT COUNT(*)
            FROM Registrations 
            WHERE national_id = OLD.national_id AND code = OLD.code
            AND waiting_status = 'registered') > 0 AND 

          (SELECT count(a.code)
                  FROM (
                    SELECT code, count(*) AS total_registered FROM Registrations
                    WHERE waiting_status = 'registered'
                    GROUP BY code ) AS a
                  LEFT JOIN Restricted_course AS b
                  ON a.code = b.code
                  WHERE a.total_registered > b.max_students 
                  AND a.code = OLD.code) > 0
    THEN
        DELETE FROM Registers
        WHERE national_id = OLD.national_id 
        AND code = OLD.code; 


    ELSIF (SELECT COUNT(*)
        FROM Registrations 
        WHERE national_id = OLD.national_id AND code = OLD.code
        AND waiting_status = 'registered') > 0 AND 

      (SELECT count(a.code)
              FROM (
                SELECT code, count(*) AS total_registered FROM Registrations
                WHERE waiting_status = 'registered'
                GROUP BY code ) AS a
              LEFT JOIN Restricted_course AS b
              ON a.code = b.code
              WHERE a.total_registered < b.max_students 
              AND a.code = OLD.code) > 0
    THEN
        DELETE FROM Registers
        WHERE national_id = OLD.national_id 
        AND code = OLD.code; 
    ELSE
        RAISE EXCEPTION 'De-registration failed';
    END IF;
    RETURN OLD;
  END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER unregister_check INSTEAD OF INSERT OR DELETE OR UPDATE ON Registrations
    FOR EACH ROW EXECUTE PROCEDURE unregister_check();