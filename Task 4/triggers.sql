CREATE VIEW CourseQueuePositions AS
  SELECT code, national_id, row_number() OVER(PARTITION BY code ORDER by in_queue ASC) AS place_in_queue
  FROM Waiting_list;


For registration:
- Meet pre-requisites (Pre-req)
- Not registered and waiting for course at the same time (not in both Waiting_list and Registers)
- Not register for course already passed (Not in Reads other than "U")
- Check if already registered (Registers)





CREATE FUNCTION register_check() RETURNS trigger AS $register_check$
  BEGIN
    --CHECK IF ALREADY PASSED--
    IF (SELECT Count(*) FROM PassedCourses WHERE national_id =NEW.national_id AND code = NEW.code)=1 THEN
      RAISE EXCEPTION 'You have already passed this course, nice try';
    END IF;


    RETURN NEW;
  END;
$register_check$ LANGUAGE plpgsql;
	
CREATE TRIGGER register_check INSTEAD OF INSERT OR UPDATE ON Registrations
    FOR EACH ROW EXECUTE PROCEDURE register_check();
