/* This is the driving engine of the program. It parses the command-line
 * arguments and calls the appropriate methods in the other classes.
 *
 * You should edit this file in two ways:
 * 1) Insert your database username and password in the proper places.
 * 2) Implement the three functions getInformation, registerStudent
 *    and unregisterStudent.
 */
import java.sql.*; // JDBC stuff.
import java.util.Properties;
import org.postgresql.util.PSQLException;
import java.io.*;  // Reading user input.
import static java.text.MessageFormat.format;


public class StudentPortal
{
    /* TODO Here you should put your database name, username and password */
    static final String USERNAME = "tda357_037";
    static final String PASSWORD = "bpyLT8Rg";

    /* Print command usage.
     * /!\ you don't need to change this function! */
    public static void usage () {
        System.out.println("Usage:");
        System.out.println("    i[nformation]");
        System.out.println("    r[egister] <course>");
        System.out.println("    u[nregister] <course>");
        System.out.println("    q[uit]");
    }

    /* main: parses the input commands.
     * /!\ You don't need to change this function! */
    public static void main(String[] args) throws Exception
    {
        try {
            Class.forName("org.postgresql.Driver");
            String url = "jdbc:postgresql://ate.ita.chalmers.se/";
            Properties props = new Properties();
            props.setProperty("user",USERNAME);
            props.setProperty("password",PASSWORD);
            Connection conn = DriverManager.getConnection(url, props);

            String student = args[0]; // This is the identifier for the student.

            BufferedReader console = new BufferedReader(new InputStreamReader(System.in));
	    // In Eclipse. System.console() returns null due to a bug (https://bugs.eclipse.org/bugs/show_bug.cgi?id=122429)
	    // In that case, use the following line instead:
	    // BufferedReader console = new BufferedReader(new InputStreamReader(System.in));
            usage();
            System.out.println("Welcome!");
            while(true) {
	        System.out.print("? > ");
                String mode = console.readLine();
                String[] cmd = mode.split(" +");
                cmd[0] = cmd[0].toLowerCase();
                if ("information".startsWith(cmd[0]) && cmd.length == 1) {
                    /* Information mode */
                    getInformation(conn, student);
                } else if ("register".startsWith(cmd[0]) && cmd.length == 2) {
                    /* Register student mode */
                    registerStudent(conn, student, cmd[1]);
                } else if ("unregister".startsWith(cmd[0]) && cmd.length == 2) {
                    /* Unregister student mode */
                    unregisterStudent(conn, student, cmd[1]);
                } else if ("quit".startsWith(cmd[0])) {
                    break;
                } else usage();
            }
            System.out.println("Goodbye!");
            conn.close();
        } catch (SQLException e) {
            System.err.println(e);
            System.exit(2);
        }
    }

    /* Given a student identification number, ths function should print
     * - the name of the student, the students national identification number
     *   and their issued login name (something similar to a CID)
     * - the programme and branch (if any) that the student is following.
     * - the courses that the student has read, along with the grade.
     * - the courses that the student is registered to. (queue position if the student is waiting for the course)
     * - the number of mandatory courses that the student has yet to read.
     * - whether or not the student fulfills the requirements for graduation
     */
    static void getInformation(Connection conn, String student) throws SQLException
    {
        // TODO: Your implementation here
    	String query = "SELECT * FROM \"studentsfollowing\" sf WHERE sf.national_id = '" + student + "'";
    	PreparedStatement ps = conn.prepareStatement(query);
    	ResultSet rs = ps.executeQuery();
    	
    	while(rs.next()) 
    	{
    		String name = rs.getString("student_name");
    		String id = rs.getString("national_id");
    		String prog = rs.getString("prog_name");
    		String br_name = rs.getString("branch_name");
    		
    		System.out.println("Information for student " + student + "");
    		System.out.println("-----------------------------------------");
    		System.out.println("Name:" + name + "");
    		System.out.println("Student ID:" + id + "");
    		System.out.println("Programme:" + prog + "");
    		System.out.println("Branch:" + br_name + "");
    		
    	}
    	
        query = "SELECT * FROM \"finishedcourses\" fc WHERE fc.national_id = '" + student + "'";
        ps = conn.prepareStatement(query);
        rs = ps.executeQuery();
       
        System.out.println("-------------------------------------");
        System.out.println("Read courses (name (code), credits: grade):");
       
        while(rs.next())
        {
            String name = rs.getString("course_name");
            String id = rs.getString("code");
            String credits = rs.getString("course_credits");
            String grade = rs.getString("grade");
           
            System.out.println(format("{0} ({1}), {2}p: {3}", name, id, credits, grade));
        }
       
        query = "SELECT * FROM \"registrations\" r WHERE r.national_id = '" + student + "'";
        ps = conn.prepareStatement(query);
        rs = ps.executeQuery();
       
        System.out.println("-------------------------------------");
        System.out.println("Registered courses (name (code): status):");
       
        while(rs.next()) 
        {
            String courseCode = rs.getString("code");
            String name = rs.getString("course_name");
            String status = rs.getString("waiting_status");
            String position = null;
           
            if(status.trim().equalsIgnoreCase("waiting")) 
            {
                position = queuePos(conn, student, courseCode);
            }
           
            if (position == null) 
            {
                System.out.println(format("{0} ({1}): {2}", name, courseCode, status));
            } else 
            {
                System.out.println(format("{0} ({1}): waiting as nr {2}", name, courseCode, position));
            }
        }
       
        query = "SELECT num_seminar, math_credits, research_credits, total_credits, graduation_status FROM \"pathtograduation\" p WHERE p.national_id = '" + student + "'";
        ps = conn.prepareStatement(query);
        rs = ps.executeQuery();
        System.out.println("-------------------------------------");
        while(rs.next()) 
        {
            int num_seminar = rs.getInt("num_seminar");
            int math_credits = rs.getInt("math_credits");
            int research_credits = rs.getInt("research_credits");
            int total_credits = rs.getInt("total_credits");
            String graduation_status = rs.getString("graduation_status");
           
            System.out.println("Seminar courses taken: " + num_seminar);
            System.out.println("Math credits taken: " + math_credits);
            System.out.println("Research credits taken: " + research_credits);
            System.out.println("Total credits taken: " + total_credits);
            System.out.println("Fulfills the requirements for graduation: " + graduation_status);
        }
    }
    
  
    private static String queuePos(Connection conn, String student, String courseCode) throws SQLException {
        String query = "SELECT place_in_queue FROM \"coursequeuepositions\" cqp WHERE cqp.code = '" + courseCode +"' AND cqp.national_id = '" + student + "' LIMIT 1";
        PreparedStatement ps = conn.prepareStatement(query);
        ResultSet rs = ps.executeQuery();
       
        while (rs.next())
        {
            return rs.getString("place_in_queue");
        }
       
        return "";
    }
    	

    /* Register: Given a student id number and a course code, this function
     * should try to register the student for that course.
     */
    static void registerStudent(Connection conn, String student, String course)
    throws SQLException
    {
    	String query = "INSERT INTO \"registrations\"(national_id, code) VALUES (" + student + ", '" + course + "')";
        PreparedStatement ps = conn.prepareStatement(query);
       
        try {
            int r =ps.executeUpdate();
            if (r > 0) System.out.println("Successfully registered " + student + " for the course: " + course);
            else System.out.println("Invalid course ID.");
        } catch (PSQLException ex) {
            if (ex.getMessage().contains("Already in the waiting list")) {
                System.out.println("Student is already on the waiting list for this course.");
            } else if (ex.getMessage().contains("Already Registered")) {
                System.out.println("Student is already registered for this course.");
            } else if (ex.getMessage().contains("You have already passed this course, nice try")) {
                System.out.println("Student has already passed this course.");
            } else if (ex.getMessage().contains("Prerequisites not met")) {
                System.out.println("Student is missing a prequisite.");
            } else {
                System.out.println(ex.getMessage());
            }
        }
    }

    /* Unregister: Given a student id number and a course code, this function
     * should unregister the student from that course.
     */
    static void unregisterStudent(Connection conn, String student, String course)
    throws SQLException
    {
    	String query = "DELETE FROM \"registrations\" r WHERE r.code = '" + course + "' AND r.national_id = '" + student + "'";
        PreparedStatement ps = conn.prepareStatement(query);
       
        int r = ps.executeUpdate();
        if (r == 0) System.out.println("Registration does not exist or invalid course ID");
        else System.out.println("Successfully unregistered " + student + " for the course: " + course);
    }
}