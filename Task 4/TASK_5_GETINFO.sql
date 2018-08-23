CREATE OR REPLACE VIEW Temp AS
SELECT CASE WHEN A.student_name IS NULL THEN B.student_name
		WHEN B.student_name IS NULL THEN C.student_name
		ELSE A.student_name END AS name, 

		CASE WHEN A.national_id IS NULL THEN B.national_id
		WHEN B.national_id IS NULL THEN C.national_id
		ELSE A.national_id END AS id, 

		CASE WHEN A.student_id IS NULL THEN C.student_id
		ELSE A.student_id END AS stud_id, 
		
		A.prog_name, 
		A.branch_name,

		CASE WHEN B.code IS NULL THEN C.code
		ELSE B.code END AS coden, 
		B.grade--, D.place_in_queue, Count(E.code) AS num_man, F.graduation_status 

FROM 
StudentsFollowing A
FULL OUTER JOIN
FinishedCourses B
ON A.national_id = B.national_id
FULL OUTER JOIN
Registrations C
ON B.national_id = C.national_id AND B.code = C.code
-- FULL OUTER JOIN
-- CourseQueuePositions D
-- ON C.national_id = D.national_id AND C.code = D.code
-- FULL OUTER JOIN
-- UnreadMandatory E
-- ON D.national_id = E.national_id
-- FULL OUTER JOIN
-- PathToGraduation F
-- ON E.national_id = F.national_id
GROUP BY name, id, stud_id, A.prog_name, A.branch_name,
 coden, B.grade--, D.place_in_queue, F.graduation_status
ORDER BY 1

