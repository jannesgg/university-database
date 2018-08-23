
CREATE TABLE Department (
  dept_abbrev varchar(50) PRIMARY KEY,
  dept_name  UNIQUE
);

CREATE TABLE Programme (
  prog_name varchar(50) PRIMARY KEY,
  prog_abbrev varchar(50) NOT NULL
);

CREATE TABLE Hosts (
  prog_name varchar(50) REFERENCES Programme,
  dept_abbrev varchar(50) REFERENCES Department,
  PRIMARY KEY (prog_name, dept_abbrev)
);

CREATE TABLE Course (
  code varchar(50) PRIMARY KEY,
  course_name varchar(50) NOT NULL,
  course_credits double precision CHECK (course_credits > 0),
  dept_abbrev varchar(50) REFERENCES Department (dept_abbrev)
);

CREATE TABLE Classification (
  class_name varchar(50) CHECK (class_name in ('mathematical','research','seminar')) PRIMARY KEY
);

CREATE TABLE Has (
  code varchar(50) REFERENCES Course,
  class_name varchar(50) REFERENCES Classification,
  PRIMARY KEY (code, class_name)
);

CREATE TABLE Restricted_Course (
  code varchar(50) REFERENCES Course,
  max_students int CHECK (max_students > 0),
  PRIMARY KEY (code)
);

CREATE TABLE Students (
  national_id text CHECK (length(national_id) = 10),
  student_id text UNIQUE,
  student_name varchar(50) NOT NULL,
  prog_name varchar(50) REFERENCES Programme(prog_name),
  PRIMARY KEY (national_id),
  UNIQUE (national_id, prog_name)
);

CREATE TABLE Branches (
  branch_name varchar(50),
  prog_name varchar(50) REFERENCES Programme(prog_name),
  PRIMARY KEY (branch_name, prog_name)
);

CREATE TABLE Reads(
  national_id text CHECK (length(national_id) = 10),
  code varchar(50),
  grade char(1) CHECK (grade in ('U','3','4','5')),
  FOREIGN KEY (code) REFERENCES Course,
  FOREIGN KEY (national_id) REFERENCES Students,
  PRIMARY KEY (national_id, code)
);

CREATE TABLE Registers (
  national_id text CHECK (length(national_id) = 10) REFERENCES Students (national_id),
  code varchar(50) REFERENCES Course (code),
  PRIMARY KEY (national_id, code)
);

CREATE TABLE Waiting_list (
  code varchar(50),
  national_id text CHECK (length(national_id) = 10),
  in_queue serial CHECK (in_queue > 0),
  PRIMARY KEY (in_queue, code),
  FOREIGN KEY (code) REFERENCES Course,
  FOREIGN KEY (national_id) REFERENCES Students
);

CREATE TABLE Picks(
  branch_name varchar(50),
  prog_name varchar(50),
  national_id text CHECK (length(national_id) = 10),
  PRIMARY KEY (national_id),
  FOREIGN KEY (branch_name, prog_name) REFERENCES Branches,
  FOREIGN KEY (national_id, prog_name) REFERENCES Students(national_id, prog_name)
 );

CREATE TABLE Br_Recommends(
  branch_name varchar(50),
  prog_name varchar(50),
  code varchar(50),
  PRIMARY KEY (branch_name, prog_name, code),
  FOREIGN KEY (branch_name,prog_name) REFERENCES Branches,
  FOREIGN KEY (code) REFERENCES Course
);

CREATE TABLE Br_Requires(
  branch_name varchar(50),
  prog_name varchar(50),
  code varchar(50),
  PRIMARY KEY (branch_name, prog_name, code),
  FOREIGN KEY (branch_name,prog_name) REFERENCES Branches,
  FOREIGN KEY (code) REFERENCES Course
);

CREATE TABLE Pre_requires(
  code_req varchar(50) REFERENCES Course,
  code_preq varchar(50) REFERENCES Course,
  PRIMARY KEY (code_req, code_preq)

);

CREATE TABLE Prog_requires(
  prog_name varchar(50) REFERENCES Programme,
  code varchar(50) REFERENCES Course,
  PRIMARY KEY (prog_name, code)
);
