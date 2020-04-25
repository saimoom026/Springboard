/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 1 of the case study, which means that there'll be more guidance for you about how to 
setup your local SQLite connection in PART 2 of the case study. 

The questions in the case study are exactly the same as with Tier 2. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT DISTINCT name
FROM `Facilities`
WHERE membercost = 0


/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT( DISTINCT name )
FROM `Facilities`
WHERE membercost =0


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance
FROM `Facilities`
WHERE membercost >0
AND membercost < ( 20 /100 ) * monthlymaintenance


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT facid, name, membercost, monthlymaintenance
SELECT *
FROM `Facilities`
WHERE facid
IN ( 1, 5 )

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance,
CASE WHEN monthlymaintenance <=100
THEN 'cheap'
ELSE 'expensive'
END AS
TYPE
FROM `Facilities`

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname, surname
FROM `Members`
WHERE joindate
IN (
SELECT MAX( joindate )
FROM `Members`
)


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT DISTINCT CONCAT( firstname, ' ', surname ) AS full_name
FROM `Members`
WHERE memid
IN (
SELECT memid
FROM `Bookings`
WHERE facid
IN ( 0, 1 )  ---Tennis court facid=(0,1)---
)


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT F.name AS facility_name, CONCAT( M.firstname, '', M.surname ) AS full_name,
CASE WHEN B.memid =0
THEN F.guestcost * B.slots
ELSE F.membercost * B.slots
END AS cost
FROM `Bookings` AS B
LEFT JOIN `Facilities` AS F ON B.facid = F.facid
AND B.starttime LIKE '2012-09-14%'
LEFT JOIN `Members` AS M ON B.memid = M.memid
WHERE (

CASE WHEN B.memid =0
THEN F.guestcost * B.slots
ELSE F.membercost * B.slots
END
) >30
ORDER BY cost DESC



/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT sub.facility_name, CONCAT( M.firstname, ' ', M.surname ) AS full_name, sub.cost
FROM Members M
INNER JOIN (
SELECT F.name AS facility_name, B.memid AS memid,
CASE WHEN B.memid =0
THEN F.guestcost * B.slots
ELSE F.membercost * B.slots
END AS COST
FROM Bookings B
INNER JOIN Facilities F ON B.facid = F.facid
AND B.starttime LIKE '2012-09-14%'
)sub ON M.memid = sub.memid
WHERE sub.cost >30
ORDER BY sub.cost DESC


/* PART 2: SQLite
/* We now want you to jump over to a local instance of the database on your machine. 

Copy and paste the LocalSQLConnection.py script into an empty Jupyter notebook, and run it. 

Make sure that the SQLFiles folder containing thes files is in your working directory, and
that you haven't changed the name of the .db file from 'sqlite\db\pythonsqlite'.

You should see the output from the initial query 'SELECT * FROM FACILITIES'.

Complete the remaining tasks in the Jupyter interface. If you struggle, feel free to go back
to the PHPMyAdmin interface as and when you need to. 

You'll need to paste your query into value of the 'query1' variable and run the code block again to get an output.
 
QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT F.name AS facility_name, 
                sub1.total_revenue 
    FROM Facilities F
    INNER JOIN 
     (SELECT F.facid,
                    sum(CASE WHEN sub2.customer_category = 'guest' THEN sub2.total_slots * F.guestcost
                    ELSE sub2.total_slots * F.membercost END) AS total_revenue
         FROM Facilities F
         
         INNER JOIN
               (SELECT F.facid,
                    CASE WHEN B.memid = 0 THEN 'guest' ELSE 'member' END AS customer_category,
                    sum(B.slots) AS total_slots
                    FROM Bookings B
         
               INNER JOIN Facilities F 
                     ON B.facid = F.facid
                     GROUP BY F.facid, customer_category) sub2 
         ON F.facid = sub2.facid
         GROUP BY F.facid) sub1 
         
    ON F.facid = sub1.facid
WHERE sub1.total_revenue < 1000
ORDER BY sub1.total_revenue


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT CONCAT( m.firstname, ' ', m.surname ) AS members, 
       CONCAT( r.firstname, ' ', r.surname ) AS recommended_by
FROM Members m
INNER JOIN Members r ON m.memid = r.recommendedby
ORDER BY recommended_by


/* Q12: Find the facilities with their usage by member, but not guests */
SELECT F.name AS facility_name, SUM( B.slots ) AS total_usage
FROM Bookings AS B
JOIN Facilities AS F ON B.facid = F.facid
WHERE B.memid !=0
GROUP BY facility_name


/* Q13: Find the facilities usage by month, but not guests */

SELECT F.name AS facility_name, SUM( B.slots ) AS total_usage, MONTHNAME( B.starttime ) AS
MONTH
FROM Bookings AS B
JOIN Facilities AS F ON B.facid = F.facid
WHERE B.memid !=0
GROUP BY facility_name,
MONTH
