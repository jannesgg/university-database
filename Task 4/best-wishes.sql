INSERT INTO Registrations VALUES('1234567891','PHY406');
INSERT INTO Registrations VALUES('1234567891','PHY400');

DELETE FROM Registrations WHERE national_id='1234567893' AND code='ART101';
DELETE FROM Registrations WHERE national_id='1234567892' AND code='TDA357';

SELECT EXISTS( SELECT * 
				FROM PassedCourses 
				WHERE national_id =NEW.national_id AND code = NEW.code)



DROP FUNCTION register_check() CASCADE;

-- CREATING NEW VIEW --

CREATE VIEW CourseQueuePositions AS
  SELECT code, national_id, row_number() OVER(PARTITION BY code ORDER by in_queue ASC) AS place_in_queue
  FROM Waiting_list;


For registration:
- Meet pre-requisites (Pre-req)
- Not registered and waiting for course at the same time (not in both Waiting_list and Registers)
- Not register for course already passed (Not in Reads other than "U")
- Check if already registered (Registers)

-- TRIGGER 1 --

CREATE OR REPLACE FUNCTION register_check() 
RETURNS trigger 
  AS $$
  BEGIN
    --CHECK IF ALREADY PASSED--
    IF EXISTS
         (SELECT * 
          FROM PassedCourses 
          WHERE national_id =NEW.national_id AND code = NEW.code) THEN
      RAISE EXCEPTION 'You have already passed this course, nice try';
    END IF;

    --CHECK IF ALREADY REGISTERED--


    RETURN NEW;
  END;
$$ 
LANGUAGE plpgsql;
  
CREATE TRIGGER register_check INSTEAD OF INSERT OR DELETE OR UPDATE 
ON Registrations
    FOR EACH ROW EXECUTE PROCEDURE register_check();

-- TRIGGER 2 --

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
        DELETE FROM Registers
        WHERE national_id = OLD.national_id 
        AND code = OLD.code; 
        INSERT INTO Registers(national_id, code)
          SELECT national_id, code FROM CourseQueuePositions
        WHERE code = OLD.code AND place_in_queue = 1;
        DELETE FROM Waiting_list
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
                  WHERE a.total_registered > b.max_students 
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

    -- CHECK IF REGISTERED AND NOT ON WAITING LIST --
    -- FIRST STUDENT FROM WAITING LIST SHOULD BE REGISTERED --
    -- CHECK COURSE AVAILABILITY --

SELECT case when count(a.code) > 0 then 'yes' else 'no' end as res
FROM (
  SELECT code, count(*) as total_registered From Registrations
  WHERE waiting_status = 'registered'
  GROUP BY code ) as a
LEFT JOIN Restricted_course as b
ON a.code = b.code
WHERE a.total_registered = b.max_students and a.code = 'ART101'



SELECT code, national_id FROM CourseQueuePositions
WHERE code = NEW.code AND place_in_queue = 1


    RETURN NEW;
  END;
$$
LANGUAGE plpgsql;

