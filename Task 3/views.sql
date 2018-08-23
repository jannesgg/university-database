-- StudentsFollowing --
CREATE VIEW StudentsFollowing AS
	SELECT Students.national_id, Students.student_id,
	Students.student_name, Students.prog_name, Picks.branch_name
	FROM Students LEFT JOIN Picks
	ON Students.national_id = Picks.national_id;

-- FinishedCourses --
CREATE VIEW FinishedCourses AS
	SELECT Students.student_name, Course.course_name, Course.course_credits,
	Reads.code, Reads.grade
	FROM Students LEFT JOIN Reads ON Students.national_id = Reads.national_id
	LEFT JOIN Course ON Reads.code = Course.code
	WHERE Reads.grade IN ('U','3','4','5');

-- Registrations --
CREATE VIEW Registrations AS
	SELECT * FROM
	Students
	RIGHT JOIN
	(SELECT
		CASE WHEN Registers.national_id IS NULL THEN Waiting_list.national_id
			ELSE Registers.national_id END AS id,
	  	CASE WHEN Registers.code IS NULL THEN Waiting_list.code
	  		ELSE Registers.code END AS code,
	  CASE WHEN Waiting_list.in_queue > 0 THEN 'waiting'
			ELSE 'registered' END AS waiting_status
	FROM
	Registers FULL OUTER JOIN Waiting_list
	ON Registers.national_id = Waiting_list.national_id
	AND Registers.code = Waiting_list.code) AS a
	ON a.id = Students.national_id;

-- PassedCourses --
CREATE VIEW PassedCourses AS
	SELECT Students.national_id, Students.student_name, Reads.code,
	Course.course_credits, Has.class_name, Reads.grade
	FROM Students INNER JOIN Reads ON Students.national_id = Reads.national_id
				INNER JOIN Course ON Reads.code = Course.code
				LEFT JOIN Has ON Course.code = Has.code
	WHERE Reads.grade IN ('3','4','5');

-- UnreadMandatory --
CREATE VIEW UnreadMandatory AS
	With Mandatory AS
	  (SELECT prog_name,code, NULL as branch_name
	    FROM Prog_requires
	  UNION
	  SELECT prog_name, code, branch_name
	    FROM Br_requires),
	StudentsFull AS
	  (SELECT Students.national_id,
	    Students.student_name, Students.prog_name, Picks.branch_name
	    FROM Students LEFT JOIN Picks
	    ON Students.national_id = Picks.national_id),
	ALLINFO AS
	  (SELECT StudentsFull.*, Mandatory.code
	    FROM StudentsFULL, Mandatory
	    WHERE StudentsFULL.prog_name = Mandatory.prog_name)
	SELECT *
	FROM ALLINFO
	WHERE NOT EXISTS (SELECT *
	                  FROM PassedCourses
	                  WHERE ALLINFO.national_id = PassedCourses.national_id AND
	                   ALLINFO.code = PassedCourses.code)
	UNION ALL
	SELECT national_id, student_name, prog_name, branch_name, NULL AS code
	FROM StudentsFollowing
	WHERE NOT EXISTS(SELECT *
	                  FROM ALLINFO
	                 WHERE StudentsFollowing.national_id = ALLINFO.national_id);

-- PathToGraduation --
CREATE VIEW PathToGraduation AS
	SELECT PassedCourses.national_id, PassedCourses.student_name, 
	sum(PassedCourses.course_credits) as total_credits, 
	count(UnreadMandatory.code) as unread_mandatory_total,
	sum(CASE WHEN PassedCourses.class_name = 'mathematical' 
		THEN PassedCourses.course_credits ELSE 0  END) AS math_credits,
	sum(CASE WHEN PassedCourses.class_name = 'research' 
		THEN PassedCourses.course_credits ELSE 0  END) AS research_credits,
	sum(CASE WHEN PassedCourses.class_name = 'seminar' 
		THEN 1 ELSE 0 END) AS num_seminar,
	CASE WHEN (count(UnreadMandatory.code) = 0)
	AND (sum(CASE WHEN PassedCourses.class_name = 'mathematical' 
		THEN PassedCourses.course_credits ELSE 0  END)) >= 20 
	AND (sum(CASE WHEN PassedCourses.class_name = 'research' 
		THEN PassedCourses.course_credits ELSE 0  END)) >= 10 
	AND (sum(CASE WHEN PassedCourses.class_name = 'seminar' 
		THEN 1 ELSE 0 END)) = 1
	THEN 'qualified'
	ELSE 'unqualified'
	END AS graduation_status

	FROM PassedCourses LEFT JOIN UnreadMandatory
	ON PassedCourses.national_id = UnreadMandatory.national_id
	AND PassedCourses.code = UnreadMandatory.code
	GROUP BY PassedCourses.national_id, PassedCourses.student_name