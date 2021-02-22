/*CHAPTER 2*/

/*Single table queries*/

USE TSQLV4;

SELECT empid, YEAR(orderdate) AS order_year, COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, order_year;

/*
The ORder of processing is showed below:

FROM 
WHERE
GROUP BY
HAVING 
SELECT
ORDER BY
*/

/*The below code returns all rows in Orders table and the 5 attributes specified in 
the SELECT statement */

SELECT empid, YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);

/*Attributes that are not in GROUP BY function are allowed only as INPUT in 
aggregate functions

Note that aggregate functions ignore NULLs except COUNT(*) which returns the
number of rows per group 
*/

SELECT
	empid,
	YEAR(orderdate) AS order_year,
	SUM(freight) AS total_freight,
	COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)

/*Return the number of unique customers return by each employee for each order year*/

SELECT
	empid,
	YEAR(orderdate) AS order_year,
	COUNT(DISTINCT custid) num_of_customers
FROM Sales.Orders
GROUP BY empid, YEAR(orderdate)

/*Using Having clause*/

SELECT 
	empid,
	YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1

/*Using AS as alias for a new column or renaming a new column is important
because the other for (<expression <alias>) has a special way of causing unintended 
problems in code.

IF comma between 2 columns is ommitted, the second column is gonna be taking as alias of 
the first column.
*/

SELECT orderid orderdate
FROM Sales.Orders;

SELECT 
	empid,
	YEAR(orderdate) AS order_year,
	COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;

/*It is incorrect to refer to aliases in the SELECT CLAUSE in the FROM, WHERE, GROUP BY
and HAVING clause. This is because the aliases are non-existent when processing these
clauses. For example, it is incorrect to refer to order_year in the WHERE clause below*/


SELECT empid, YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE order_year > 2015;

/*Instead use the below*/

SELECT empid, YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE YEAR(orderdate) > 2015;

/*A similar problem can happen if we refer to aliases in the HAVING CLAUSE*/

SELECT empid, YEAR(orderdate) AS order_year, COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING num_of_orders > 1

/*Just like the problem above, the COUNT should be referenced at the HAVING clause*/

SELECT empid, YEAR(orderdate) AS order_year, COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;

/*SQL is based on multiset theory. In some aspects the set does not allow for duplicates
as long as there is a key on the relation. Without the key, the table can have duplicates
and therefore is not relational. SQL query do not have keys , therefore can have duplicates
For example, Orders table has a primary key orderid column. yet, the query against the 
Orders table return DUPLICATES.
*/

SELECT empid, YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE custid = 71;

/*Using the DISTINCT clause, SQL Query can remove duplicates*/
SELECT DISTINCT empid, YEAR(orderdate) AS order_year
FROM Sales.Orders
WHERE custid = 71;

/*It is invalid to refer to aliases in the SELECT clause, even if it is used just
right after specifying the aliases. To get around the problem, we use the YEAR(orderdate) */


SELECT
	orderid,
	YEAR(orderdate) AS order_year,
	order_year + 1 AS next_year
FROM Sales.Orders


SELECT
	orderid,
	YEAR(orderdate) AS order_year,
	YEAR(orderdate) + 1 AS next_year
FROM Sales.Orders

/*ORDER BY clause. To ensure that result of a query is well presented. ORDER BY clause
is used. Otherwise, there is no guarantee that the query results would be ordered.
Ordered query results do not qualify as a table as a result are called CURSORS
Unordered query results however are TABLES because they are unordered because it is a 
fundamental feature of a set. STANDARD SQL has provided a distinction between table and cursor
because there are some table expressions and set operators that depend primarily on table
as INPUTS*/

SELECT empid, YEAR(orderdate) AS order_year, COUNT(*) AS num_of_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, order_year;

/*The column that is not in SELECT clause can also be used order a query*/

SELECT empid, firstname, lastname, country
FROM HR.Employees
ORDER BY hiredate;

/*The column that is not in SELECT clause can also be used to order a query.
The below is an illegal query because the empid is not in the SELECT DISTINCT clause*/

SELECT DISTINCT country
FROM HR.Employees
ORDER BY empid;

/*TOP OFFSET-FETCH filters*/

/*TOP filter is used to limit the number and percentage of rows a query returns.
The TOP filter relies on the ORDER BY specification. THis means that if DISTINCT is
specified in the SELECT clause, the TOP filter is evaluated after duplicate row has
been removed*/

/*To return the five most recent orders*/

SELECT TOP (5)
	orderid,
	orderdate,
	custid,
	empid
FROM Sales.Orders
ORDER BY orderdate DESC;

/*This returns the top 1 percent of the qualifying rows*/

SELECT TOP (1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

/*THe ORDER BY clause here has no unique listing because orderdate is not a primary
/candidate key. Therefore the query result obtained is non-deterministic. That is, no specific
order used to obtain query result. To ensure result is deterministic, a tiebreaker is 
used as shown below. The tiebreaker is usually a primary/unique key that can properly identify each 
row in the source table.Example shown below
*/

SELECT TOP (5) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;

/*
Instead of resolving the ties. We can obtain result with TIES. We can say in addition
to the top 5 elements, we wanna return all other rows with the same sort value. This can
be achieved by adding the WITH TIES option, as shown in the following query.
*/

SELECT TOP (5) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

/*OFFSET-FETCH filter

The TOP filter has 2 shortcomings-- it is not standard and it does not include skipping capability.
However, T-SQL also support a TOP-like filter which supports skipping option. THis makes
it useful for ad-hoc paging purposes.

Note: OFFSET-FETCH must have an ORDER BY clause. T-SQL does not support FETCH clause
without OFFSET clause. If we do not wanna skip any rows but wanna fetch some rows.
OFFSET 0 ROWS is used. Also OFFSET without FETCH is allowed.

T-SQL(as at 2016) does not yet support TOP PERCENT and WITH TIES
*/

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;



/*
WINDOW FUNCTION

This operates on a set of rows exposed to it by the OVER clause. The OVER clause can restrict
the rows in the window by using the window parttion subclause(PARTITION BY). It can
define ordering for the calculation using the window order clause (ORDER BY)-- This is 
not to be confused with the query's presentation ORDER BY clause.

The ROW_NUMBER() function must produce unique, sequential, and increasing values within each partition. The 
ROW_NUMBER function must also increase regardless of whether its ORDER BY list is
non-unique. 
*/

SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid
						ORDER BY val) AS row_num
FROM Sales.OrderValues
ORDER BY custid, val;



/*	PREDICATES and OPERATORS	*/

/*
T-SQL has language lements where predicates can be specified such as WHERE, HAVING
and CHECK constraints and others.

Example of predicates supported by T-SQL include IN, BETWEEN and LIKE
*/

/* IN checks whether a value is equal to at least one of the elements in a set
The following returns orders in which the order ID is equal to 10248, 10249, or 10250:
*/

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid IN (10248, 10249, 10250);

/*
BETWEEN predicate checks whether a value is in a specified range.
For example, the following query returns all orders in the inclusive range 10300 through 10310:
*/

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid BETWEEN 10300 AND 10310;


/* With LIKE predicate, we check whether a character string meets a specified pattern*/

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE 'D%';

/*	
T-SQL supports the following comparison operators: =, >, <, >=, <=, <>, !=, !>, !<, of
which the last three are not standard. Because the nonstandard operators have standard
alternatives (such as <> instead of !=).

the following query returns all orders placed on or after January 1, 2016:	*/

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20160101';

/* We can combine logical expressions with AND, OR and NOT operator	*/

/*	The following query returns orders placed on or after January 1, 2016, that
 were handled by one of the employees whose ID is 1, 3, or 5:*/

 SELECT orderid, empid, orderdate
 FROM Sales.Orders
 WHERE orderdate >= '20160101' AND empid IN (1, 3, 5);

 /*
 T-SQL supports the four obvious arithmetic operators: +, �, *, and /. It also supports the %
operator (modulo), which returns the remainder of integer division.
 */

SELECT orderid, productid, qty, unitprice, discount,
	qty * unitprice * (1 - discount) AS val
FROM Sales.OrderDetails;

/*If both operands are of the same datatype, the result would result in the same datatype
For example, 5/2 will result in 2. To make it return 2.5. The datatype is CAST as NUMERIC
therefore col1/col2 becomes CAST(col1 AS NUMERIC(12, 2)) / CAST(col2 AS NUMERIC(12, 2))

If the two operands are of different types, the one with the lower precedence is promoted
to the one that is higher. For example, 5/2.0. Because NUMERIC is higher than INT. The INT
5 isn implicitly converted NUMERIC 5.0 before tghe arithmetic operation and 2.5 is gotten 
*/

/*
	OPERATOR PRECEDENCE
1. () (Parentheses)
2. * (Multiplication), / (Division), % (Modulo)
3. + (Positive), � (Negative), + (Addition), + (Concatenation), � (Subtraction)
4. =, >, <, >=, <=, <>, !=, !>, !< (Comparison operators)
5. NOT
6. AND
7. BETWEEN, IN, LIKE, OR
8. = (Assignment)

*/

/*The query returns orders that were either �placed by customer 1 and handled by employees
1, 3, or 5� or �placed by customer 85 and handled by employees 2, 4, or 6.�*/

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE 
	custid = 1
	AND empid IN (1, 3, 5)
	OR custid = 85
	AND empid IN (2, 4, 6);

/*	Using PARENTHESES. The below is a logical equivalent of the above query	*/
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE
	(custid = 1
	AND empid IN(1, 3, 5))
	OR
	(custid = 85
	AND empid IN(2, 4, 6));

/* Using parentheses to force precedence with logical operators is similar to using
parentheses with arithmetic operators.	*/

SELECT 10 + 2 * 3

SELECT (10 + 2) * 3;

/*	CASE EXPRESSION	

THis is a scalar expression that returns a value based on conditional logic. It is based
on SQL standard. CASE is an expression and not a STATEMENT; that is, it does not take
action such as controlling the flow of your code. It returns value. Because it is a scalar
expression, it is allowed wherever scalar expressions are allowed such as SELECT, WHERE,
HAVING, and ORDER BY clauses and in CHECK constraints

There are 2 forms of CASE expressions: simple and searched. We use simple to compare one
value/ scalar expression with a list of possible values and return a value for first match.
If no valuein the list CASE expression returns value in then ELSE clause otherwise it 
defaults to ELSE NULL.

The simple CASE form has a single test value that is compared to a list of possible
values. The searched CASE form allows for the use of predicates in the WHEN clause.

T-SQL supports some functions you can consider as abbreviations of the CASE expression:
ISNULL, COALESCE, IIF, and CHOOSE. Note that of the four, only COALESCE is standard.
*/
SELECT productid, productname, categoryid,
	CASE categoryid
		WHEN 1 THEN 'Beverages'
		WHEN 2 THEN 'Condiments'
		WHEN 3 THEN 'Confections'
		WHEN 4 THEN 'Dairy Products'
		WHEN 5 THEN 'Grains/Cereals'
		WHEN 6 THEN 'Meat/Poultry'
		WHEN 7 THEN 'Produce'
		WHEN 8 THEN 'Seafood'
		ELSE 'Unknown Category'
	END AS category_name
FROM Production.Products;

SELECT orderid, custid, val,
	CASE 
		WHEN val < 1000.00					 THEN 'Less than 1000'
		WHEN val BETWEEN 1000.00 AND 3000.00 THEN 'Between 1000 and 3000'
		WHEN val > 3000.00					 THEN 'More than 3000'
		ELSE 'Unknown'
	END AS value_category
FROM Sales.OrderValues

/*
SQL uses a 3-valued predicate logic. However, it has different meanings in SQL
language elements. This made it impossible to equate 'accept TRUE' and 'reject FALSE'
For example, The treatment SQL has for query filters is 'accept TRUE' while
for CHECK constraint, it 'rejects FALSE'.

SQL treats NULLs inconsistently in different language elements for comparison and sorting purposes.
Some treat 2 NULLs as same while others treat them differently.
For grouping and sorting purposes-- 2 NULLs are considered the same
In ORDER BY: SQL standard leaves this to product implementation. It can either come before
or after values. However, it must be consistent within the implementation. T-SQL sorts NULLs
before present values

For the purposes of ensuring a UNIQUE constraint, standard SQL treats NULLs as different 
from each other(thereby allowing multiple NULLs). Conversely, in T-SQL, a UNIQUE constraint 
considers 2 NULLs as equal(allowing only one NULL).

*/

/* The query returns all customers where region is equal to WA*/

SELECT custid, country, region, city
FROM Sales.customers
WHERE region = 'WA';

/* The query returns all customers where region is different than WA*/

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region <> 'WA';

/* Same output is gotten as above if NOT operator is used*/

SELECT custid, country, region, city
FROM Sales.customers
WHERE NOT(region = 'WA');

/* To output values where region is NULL. Dont use region = NULL expression.
THis is because ti is gonna evaluate to unknown. Why? NULL = NULL outputs UNKNOWN
because a missing value can be different or same with other missing values */

SELECT custid, country, region, city
FROM Sales.customers
WHERE region IS NULL;

/* If we wanna output rows with region attribute is different than WA, including
those in which the value is missing. Use the below*/

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region <> 'WA' OR region IS NULL;


/*	ALL-AT-ONCE OPERATIONS

This means that all expressions oin the same logical processing phase are evaluateed logically
at the same point in time. The reason for this is that all expressions that appear in the same logical
phase are treated as a set, and as mentioned earlier, a set has no order to its elements.

This concept explains why we cannot refer to column aliases assigned in a SELECT clause
in the same SELECT clause. 

order_year in the 3rd expression in the query below is invalid because the whole expressions
are processed at once and there is no order of processing.

*/

SELECT 
	orderid,
	YEAR(orderdate) AS order_year,
	order_year + 1 AS next_year
FROM Sales.Orders;

/* To return col1, col2 in a table T1 where col1/col2 > 2. To avoid division-by-zero error
The query below is used*/

SELECT col1, col2
FROM dbo.T1
WHERE col2 <> 0 AND col1/col2 > 2;


/*	COLLATION

This is a property of character data that encapsulates several aspects such as:
language support, case sensitivity, accent sensitivity and more. To get the set of
supported collations and their descriptions. you can query the table 
function fn_helpcollations as follows.
*/

SELECT *
FROM sys.fn_helpcollations();

/*The following runs in a case-insensitive environment*/

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = 'davis';

/* If we wanna make the filter case-sensitive even though the column's collation is
case-insensitive, we can convert the collation of the expression as follows.

This time the query returns an empty set because no match is found when a case-sensitive
comparison is used. 
*/

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS = N'davis';


/*	OPERATORS and FUNCTIONS	

This section covers string concatenation and functions that operate on character strings.
For string concatenation, T-SQL provides (+) operator and the CONCAT function.
For other operations on character strings, T-SQL provides several functions including
SUBSTRING, LEFT, RIGHT, LEN, DATALENGTH, CHARINDEX, PATINDEX, REPLACE, REPLICATE
STUFF, UPPER, LOWER, RTRIM, LTRIM, FORMAT, COMPRESS, DECOMPRESS and STRING_SPLIT.

It is important to note that there is no SQL standard functions library-- They are all
implementation specific*/

/* String concatenation operator and CONCAT function*/

/*The query below produces fullname column by concatenating firstname, a space, lastname*/

SELECT empid, firstname + ' ' + lastname AS full_name
FROM HR.Employees;

/*	Standard SQL dictates that a concatenation with a NULL yeild a NULL. This is the default
behavior of T-SQL. For example, consider the query against the Customers table. Some 
customers have NULL in the region column. Hence SQL Server returns NULL for those customers*/

SELECT custid, country, region, city,
	country + ',' + region + ',' + city AS location
FROM Sales.Customers;

/*To treat a NULL as an empty string-- or more accurately to replace the NULL with an empty
string-- we can use the COALESCE function.

The COALESCE function accepts a list of input values and returns the first that is not NULL.
We can revise the query above to avoid SQL Server retuirning NULL*/

SELECT custid, country, region, city,
	country + COALESCE(',' + region, '') + ',' + city AS location
FROM Sales.Customers;

/*	The problem of outputing NULL using the (+ plus) operator can also be surmounted using the
CONCAT function. This automatically makes a NULL an empty string
*/

SELECT custid, country, region, city,
	CONCAT(country, ',' + region, ',' + city) AS location
FROM Sales.Customers;

/* SUBSTRING function

Syntax: SUBSTRING(string, start, length)

If the length argument exceeds the character length, the function returns everything 
without raising an error

LEFT and RIGHT functions

Syntax: LEFT(string, n), RIGHT(string, n)

LEFT and RIGHT functions are abbreviations of SUBSTRING function. They return 'n' number of
characters from left to right of the string

*/

SELECT SUBSTRING('abcde', 3, 3);

SELECT RIGHT('abcde', 3);

SELECT SUBSTRING('abcde', 3, 3); -- Implementation of the above code using SUBSTRING 

SELECT LEFT('abcde', 3);

SELECT SUBSTRING('abcde', 1, 3) -- Implementation of the above code using SUBSTRING 

/*	
	LEN and DATALENGTH function	

LEN-- This gives number of characters in input string
DATALENGTH-- This gives number of bytes in input string

For regular characters, LEN and DATALENGTH returns same number because 1char = 1byte
For Unicode characters, LEN and DATALENGTH returns different numbers because 1char >= 2bytes

Note: Another important distinction between the two is that LEN excludes trailing spaces.
Meanwhile, DATALENGTH does not leave out trailing spaces.

	CHARINDEX function

This returns the position of a substring in a string

CHARINDEX(substring, string, start_pos) 

start_pos is an optional argument that tells the function where to start looking. If substring is
not found, function returns 0.

	PATINDEX function

This returns the position of the first occurence of a pattern within a string. The example 
below shows hwo to find the position of the first occurence of a digit in a string.
	REPLACE function
This replaces all occurence of a substring1 in string with substring2

Syntax: REPLACE(string, substring1, substring2)

	REPLICATE function
This replicates a string a certin number of times.

Syntax: REPLICATE(string, n)-- This repeats string 'n' number of times

	STUFF function
This replaces a substring with another string 

Syntax: STUFF(string, pos, delete_length, insert_string)

	RTRIM and LTRIM function
This removes leading and trailing spaces of an input string

	FORMAT function
This format an input value as a charcater string based on MIcrosoft .NET format string 
and an optional culture specification.

Syntax: FORMAT(input, format_string, culture)..

Generally, we should refrain from using it because of performance issue

	COMPRESS and DECOMPRESS functions
The COMPRESS and DECOMPRESS functions use the GZIP algorithm to compress and
decompress the input, respectively. Both functions were introduced in SQL Server 2016.

	STRING_SPLIT function
The STRING_SPLIT table function splits an input string with a separated list of values into the
individual elements. This function was introduced in SQL Server 2016.
*/

SELECT LEN('abcde');

SELECT DATALENGTH('abcde');		-- Both give same numbers

SELECT LEN(N'abcde');

SELECT DATALENGTH(N'abcde');		-- This gives twice the number of the one above

SELECT CHARINDEX(' ', 'Itzik Ben-Gan')

SELECT PATINDEX('%[0-9]%', 'abcd123efgh'); -- This outputs 5

SELECT REPLACE('1-a 2-b','-', ':');

/*Using REPLACE function to calculate the number of occurence of a character character
The following query returns number of times character e appears in the lastname attribute*/

SELECT empid, lastname, 
	LEN(lastname) - LEN(REPLACE(lastname, 'e', '')) AS num_e_occurence
FROM HR.Employees;

SELECT REPLICATE('abc', 3);

/*Using REPLICATE function, along with RIGHT function and string concatenation to return
a 10-digit string representation of the supplier ID integer with leading zeros*/

SELECT supplierid,
	RIGHT(REPLICATE('0', 9) + CAST(supplierid AS VARCHAR(10)), 10) AS str_supplierid
FROM Production.Suppliers;

/* T-SQL has a FORMAT function that you can use to acieve such formatting needs much more easily, albeit at a
higher cost*/

/*The below removes y in 'xyz' and replaces it with 'abc' */

SELECT STUFF('xyz', 2, 1, 'abc'); -- This deletes only y

SELECT STUFF('xyz', 2, 2, 'abc'); -- This deletes yz

SELECT STUFF('xyz', 2, 0, 'abc'); -- We can just insert 'abc' from pos 2 without deleting any character

SELECT '	abc	';

SELECT RTRIM('	abc	'); -- This removes trailing spaces

SELECT LTRIM('	abc	'); -- This removes leading spaces

SELECT RTRIM(LTRIM('	abc	'));

SELECT FORMAT(1759, '0000000000');

SELECT COMPRESS(N'This is my cv. Imagine it was much longer.') -- This is available in SQL server 2016 and above

/* To insert @empid and compressed @cv(Uncompressed CV) into an EmployeeCVs in your database */

INSERT INTO dbo.EmployeeCVs(empid, cv) VALUES (@empid, COMPRESS(@cv));

/* The below does not return the original string charcaters instead returns a binary value*/

SELECT DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was much longer.'));

/* To return orginal string in the code above, we CAST the decompressed input to target
character string type*/

SELECT 
	CAST(
		DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was much longer.'))
		AS NVARCHAR(MAX));

/* To return the uncompressed form of the employee resumes. USe the below query*/

SELECT empid, CAST(DECOMPRESS(cv) AS NVARCHAR(MAX)) AS cv
FROM dbo.EmployeeCVs;  -- Invalid table. Just for illustration.


/*	Block of code to be tried*/

SELECT STRING_SPLIT('10248,10249,10250', ',') AS S; -- available in 2016 SQL Server and above

SELECT CAST(value AS INT) AS my_value
FROM STRING_SPLIT('10248,10249,10250', ',') AS S;

/*LIKE PREDICATE

	%(percent) wildcard
This represents a string of any size including empty string

	_(underscore) wildcard
This represents a single character

	[<list of characters>] wildcard
This represents a single character that must be one of the characters in the list.

	[<character>-<character>] wildcard
This represents a single character within the range specified.

	[^<character list or range>] wildcard
This represents a single character that is not in the character list.

	ESCAPE character
If you wanna search for a character that is also used as a wildcard, you can use an 
ESCAPE character. Specify a character that we know for sure does not appear in the data
as the escape character in front of the character you are looking for, specify the 
ESCAPE keyword followed by the 'escape character' right after the pattern.

Check whether a col1 contains an underscore(_)
col1 LIKE '%!_%' ESCAPE '!'

*/

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE 'D%';

/*The following returns employees where the second character in the lastname is e*/

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE '_e%';

/*
The following query returns employees where first character in the last name
is A, B, or C.
*/

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE '[ABC]%';

/*
The following query returns employees where first character in the last name
is letter in the range A through E, inclusive, taking the collation into account.
*/

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE '[A-E]%';

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE '[^A-E]%';


/*	DATE and TIME data types
First, there are 2 legacy date and time dsta types. Example DATETIME and SMALLDATETIME.
There are now 4 more additions post-2008 SQL Server. Example, DATE, TIME, DATETIME2 and
DATETIMEOFFSET. 

It is important to note that DATE and TIME data types provide a separartion between the
date and time components if you need it. DATETIME2 has a bigger date range and precision
than the legacy types. DATETIMEOFFSET also includes offset from UTC. 

Of note is that, TIME, DATETIME2 and DATETIMEOFFSET depend on the precision chosen. Thne precsion 
is usually represented as integers between 0-7. 

TIME(0) -- connotes precision at fractional-second.
TIME(3) -- connotes precision at one-millisecond.
TIME(7) -- connotes precision at 100-nanosecond.

T-SQL does not have a way of to represent date and time literal. Instead there is an implicit
conversion of one data type to the other based on data-type precedence.

To change overall default language in your session, use SET LANGUAGE.

TO change date format, use SET DATEFORMAT.

SET LANGUAGE/SET DATEFORMAT are only affecting how SQL server interprets the input string
and not the output of the result.

It is recommended that language-neutral datetime literal is used because of other readers 
from another country /region that wanna look at your code.

literal expressed as 'YYYYMMDD' is not affected by the language settings. and therefore 
is best practise.
*/

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate = '20160212';

/* Implicit conversion happens above from string literal to a datetime.

Below is an explicit conversion of character string to a DATE
*/

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate = CAST('20160212' AS DATE);


SET LANGUAGE British;
SELECT CAST('02/12/2026' AS DATE);

SET LANGUAGE us_english;
SELECT CAST('02/12/2026' AS DATE);

/* When language-neutral date format is used, the result stays the same regardless of
language settings*/

SET LANGUAGE British;
SELECT CAST('20260212' AS DATE);

SET LANGUAGE us_english;
SELECT CAST('20260212' AS DATE);

/* We might wanna convert to a specific style. SQL Server book online should be used
to check the style number

CONVERT function can be used for this purpose.
Its equivalent PARSE can also be seen below.

NOTE: PARSE is significantly more expensive than the CONVERT function. Hence refrain
from using it.
*/

SELECT CONVERT(DATE, '02/12/2016', 101); -- 101 is 'MM/DD/YYYY'

SELECT PARSE('02/12/2016' AS DATE USING 'en-US'); -- 101 is US english

SELECT CONVERT(DATE, '02/12/2016', 103); -- 103 is 'DD/MM/YYYY'

SELECT PARSE('02/12/2016' AS DATE USING 'en-GB') -- 103 is british english


/*	WORKING WITH DATE and TIME spearately	*/

IF OBJECT_ID(N'Sales.Orders2', N'U') IS NOT NULL DROP TABLE Sales.Orders2;

/*

For current SQL server we use as shown below

DROP TABLE IF EXISTS Sales.Orders2;
*/

SELECT orderid, custid, empid, CAST(orderdate AS DATETIME) AS orderdate
INTO Sales.Orders2
FROM Sales.Orders;

/* The orderdate in teh Sales.Order2 now is a datetime. with the TIME component set to midnight.
With this modification, RANGE filter is not necessary. Hence, equality operator can be used
*/

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders2;

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders2
WHERE orderdate = '20160212';

/*
We can use CHECK constraint to ensure that only midnight is used as the time part. This can
be accomplished using the CONVERT function. The CONVERT function below extracts only the 
time portion of the orderdate value using the style 114.
*/

ALTER TABLE Sales.Orders2
	ADD CONSTRAINT CHK_Orders2_orderdate
	CHECK(CONVERT(CHAR(12), orderdate, 114) = '00:00:00:000');

/* If time component is stored with nonmidnight values, you can use a range filter like
this*/

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders2
WHERE orderdate >= '20160212' AND orderdate < '20160213';

/* 
IF we wanna work in legacy types, you can store all values with the base date of
January 1, 1900. When SQL server converts a character string literal that contains only
a time component to DATETIME or SMALLDATETIME, SQL server assumes the date is the base date.  
 */

 /*	Run the below for cleanup	*/

 IF OBJECT_ID(N'Sales.Orders2', N'U') IS NOT NULL DROP TABLE Sales.Orders2;

 
 /*	FILTER DATE RANGES
 
 If we wanna filter date ranges whole year and month, it seems natural to use
 YEAR and MONTH. The below is a query that returns orders placed in year 2015.

 Note: in order to use an INDEX efficiently, we dont manipulate the filtered column.
 To be able to use INDEX efficiently, we dont manipulate the filtered column. Hence,
 we use a range filter.
 */

 SELECT orderid, custid, empid, orderdate
 FROM Sales.Orders
 WHERE YEAR(orderdate) = 2015;

 SELECT orderid, custid, empid, orderdate
 FROM Sales.Orders
 WHERE orderdate >= '20150101' AND orderdate < '20160101';

 /*	Similarly, instead of using functions to filter orders placed in a particular
 month like below we instead use a range filter*/

 SELECT orderid, custid, empid, orderdate
 FROM Sales.Orders
 WHERE YEAR(orderdate) = 2016 AND MONTH(orderdate) = 2;

 SELECT orderid, custid, empid, orderdate
 FROM Sales.Orders
 WHERE orderdate >= '20160201' AND orderdate < '20160301';

 /*	Date and time functions
 
 In this section, We describe functions that operate on date and time data types including
 GETDATE, CURRENT_TIMESTAMP, GETUTCDATE, SYSDATETIME, SYSUTCDATETIME, SYSDATETIMEOFFSET,
 CAST, CONVERT, SWITCHOFFSET, AT TIME ZONE, TODATETIMEOFFSET, DATEADD, DATEDIFF, DATEDIFF_BIG,
 DATEPART, YEAR, MONTH, DAY, DATENAME, various FROMPARTS functions and EOMONTH.
 */

 /* Current date and time	
 
 The following are niladic (parameterless) function used to obtain current date and time values
 GETDATE, CURRENT_TIMESTAMP and GETUTCDATE are for legacy DATETIME type. However, SYSDATETIME
 , SYSUTCDATETIME and SYSDATETIMEOFFSET
 
 The code below demonstrates using the current date and time functions
 */

 SELECT
	GETDATE()	AS get_date,
	CURRENT_TIMESTAMP AS current_time_stamp,
	GETUTCDATE() AS get_utc_date,
	SYSDATETIME() AS sys_datetime,
	SYSUTCDATETIME() AS sys_utc_datetime,
	SYSDATETIMEOFFSET() AS sys_datetime_offset;

/* None of the functions above gives only date or time. To do this, we use the 
CAST function*/

SELECT
	SYSDATETIME() AS current_datetime,
	CAST(SYSDATETIME() AS DATE) AS 'current_date',
	CAST(SYSDATETIME() AS TIME) AS 'current_time';

/*
CAST, PARSE and CONVERT can cause a query to fail if they fail to succesfully convert their input value
into a target value. However, to prevent query from failing, we use their corresponding counterparts
with same arguments such as TRY_CAST, TRY_PARSE, TRY_CONVERT.

TRY_CAST(input_value AS target)
TRY_PARSE(input_value AS target USING culture)
TRY_CONVERT(target, input_value, style_number)

CAST is standard. PARSE and CONVERT are not. So, it is recommended to use CAST
*/

SELECT CAST(CAST(CURRENT_TIMESTAMP AS DATE) AS DATETIME);

SELECT CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112);

/*
SWITCHOFFSET adjusts an input DATETIMEOFFSET value to a specified target offset from UTC

Syntax: SWITCHOFFSET(datetimeoffset_value, UTC_offset)
*/

SELECT
	SYSDATETIMEOFFSET() AS sys_datetime_offset,
	SWITCHOFFSET(SYSDATETIMEOFFSET(), '+05:00') AS switch_offset_value;

/*
	TODATETIMEOFFSET

This is different from SWITCHOFFSET statement because because it accepts local date and time
 without the offset component.

 Its major use is that it transforms a non-offset-aware data to an offset-aware data.
 
 Syntax: TODATETIMEOFFSET(local_date_and_time_value, UTC_offset)
 
	AT TIME ZONE function 

This accepts an input date and time value and converts it to a datetimeoffset value that corresponds to the specified
target time zone. It is introduced in SQL Server 2016.

Syntax: dt_val AT TIME ZONE time_zone

dt_val can be DATETIME, SMALLDATETIME, DATETIME2, DATETIMEOFFSET
time_zone can be any of windows time-zone namea as they appear in then name column in the 
sys.time_zone_info view

*/

/*
To use the following query to see the available timezones, their current offset from UTC
and whether it's currently DAylight Savings Time(DST).
*/

/* Concept quite ambiguous for now*/
SELECT name, current_utc_offset, is_current_dst
FROM sys.time_zone_info;

SELECT 
	CAST('20160212 12:00:00.0000000' AS DATETIME2)
		AT TIME ZONE 'Pacific Standard Time' AS val1,
	CAST('20160212 12:00:00.0000000' AS DATETIME2)
		AT TIME ZONE 'Pacific Standard Time' AS val2;

SELECT
	CAST('20160212 12:00:00.0000000 -05:00' AS DATETIMEOFFSET)
		AT TIME ZONE 'Pacific Standard Time' AS val1,
	CAST('20160812 12:00:00.0000000 -04:00' AS DATETIMEOFFSET)
		AT TIME ZONE 'Pacific Standard Time' AS val2;


/*
	The DATEADD function

This add aspecified amount of 'n' units to an input date/time/datetime value based on 
the specified part

Syntax: DATEADD(part, n, dt_val)

	DATEDIFF and DATEDIFF_BIG functions

This functions find the difference between 2 datetime values based based on specified part

Syntax: DATEDIFF(part, dt_val1, dt_val2) -- This returns 4-byte INT
Syntax: DATEDIFF_BIG(part, dt_val1, dt_val2) -- This returns 8-byte INT

Maximum INT value (2,147,483,647). DATEDIFF_BIG is useful when the returned value is 
higher than (2,147,483,647).

	DATEPART function

This returns an integer representing a requested part of a date and time

Syntax: DATEPART(part, dt_val)
	*/

/* The below add one year to Febuary 12, 2016	*/

SELECT DATEADD(YEAR, 1, '20160212');

/* This returns difference in terms of days of days between 2 date values*/

SELECT DATEDIFF(DAY, '20160212', '20170212');

/* Lets find the millisecond difference between two date values, The code below results in
an overflow. Therefore to accomodate the big value, we use DATEDIFF_BIG function
*/

SELECT DATEDIFF(MILLISECOND, '00010101', '20160212'); -- This results in an OVERFLOW

SELECT DATEDIFF_BIG(MILLISECOND, '00010101', '20160212'); -- This is valid in 2016 SQL server and above

/*
Instead of computing the beginning and end day of an input date and time value using CAST 
function, we use a more complicated approach requiring the sophisticated use of DATEDIFF
and DATEADD.
*/

SELECT 
	DATEADD(
		DAY,
		DATEDIFF(DAY, '19000101', SYSDATETIME()), '19000101');

/* The below returns the first day of the current month*/

SELECT 
	DATEADD(
		MONTH,
		DATEDIFF(MONTH, '19000101', SYSDATETIME()), '19000101');

/* Thne below returns the first day of the current year*/

SELECT 
	DATEADD(
		YEAR,
		DATEDIFF(YEAR, '19000101', SYSDATETIME()), '19000101');


SELECT DATEPART(MONTH, '20160212');

SELECT DATEPART(YEAR, '20160212');

SELECT DATENAME(MONTH, '20160212'); -- Its apt to say this work majorly for naming MONTh

SELECT DATENAME(YEAR, '20160212'); -- This returns integer instead of string

SELECT DATENAME(DAY, '20160212'); -- This also returns integer

/* ISDATE function works to check if a date is valid. It returns 1 if true and 0 otherwise*/

SELECT ISDATE('20160212');

SELECT ISDATE('20160230');

/*
	FROMPARTS functions
The FROMPARTS functions accept integer inputs representing parts of a date and time value
and construct a value of the requested type from those parts.

Syntax:
DATEFROMPARTS (year, month, day)
DATETIME2FROMPARTS (year, month, day, hour, minute, seconds, fractions, precision)
DATETIMEFROMPARTS (year, month, day, hour, minute, seconds, milliseconds)
DATETIMEOFFSETFROMPARTS (year, month, day, hour, minute, seconds, fractions,
hour_offset, minute_offset, precision)
SMALLDATETIMEFROMPARTS (year, month, day, hour, minute)
TIMEFROMPARTS (hour, minute, seconds, fractions, precision)
*/

SELECT
	DATEFROMPARTS(2016, 02, 12),
	DATETIME2FROMPARTS(2016, 02, 12, 13, 30, 5, 1, 7),
	DATETIMEFROMPARTS(2016, 02, 12, 13, 30, 5, 997),
	DATETIMEOFFSETFROMPARTS(2016, 02, 12, 13, 30, 5, 1, -8, 0, 7),
	SMALLDATETIMEFROMPARTS(2016, 02, 12, 13, 30),
	TIMEFROMPARTS(13, 30, 5, 1, 7);

/*
	EOMONTH function

THis returns the end-of-month of the inputed date and time. An optional argument can also be 
provided to add/ subtract to the month of the input date.

Syntax: EOMONTH(input[, months_to_add])
*/

SELECT EOMONTH(SYSDATETIME());

SELECT EOMONTH(SYSDATETIME(), 5);

/*	The following return orders place at the last day of the month	*/
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

/* The following returns orders placed on the first day of each month*/
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate LIKE '%01';

/*
SQL server provides tools for getting information abpur the metadata of objects such as
information about tables in a database and columns in a table. Those tools include catalog
views, information schema views, system stored procedures and functions.
*/

/* Catalog views contain information about objects in the database, including information
that is specific to SQL server.

To list the tables along with their schema in the database, we query sys.tables view.
SCHEMA_NAME converts ID integer to its name
*/

SELECT SCHEMA_NAME(SCHEMA_ID) AS table_schema_name, name AS table_name
FROM sys.tables;

/* To return columns in the Sales.Orders table	*/

SELECT
	name AS column_name,
	TYPE_NAME(system_type_id) AS column_type,
	max_length,
	collation_name,
	is_nullable
FROM sys.columns
WHERE object_id = OBJECT_ID(N'Sales.Orders');

/*
Information schema views

An information schema view is a set of views that resides in a schema called
INFORMATION_SCHEMA and provides metadata information in a standard manner. That is,
the views are defined in the SQL standard, so naturally they don't cover metadata aspects
or objects specific to SQL Server (such as indexing).

The query below return the INFORMATION_SCHEMA.TABLES view lists the user tables in the 
current databse along with their schema names.
*/

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES;

/* The query against the INFORMATION_SCHEMA.COLUMNS provides most of the available
information about columns in the Sales.Orders table	*/

SELECT
	COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
	COLLATION_NAME, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'Sales' AND TABLE_NAME = N'Orders';


/* System stored procedures and functions

This internally query the system catalog and give you back more digested metadata information.

sp_tables: returns a list of objects (tables and views) that can be queried in the current
database'

sp_help: accepts object name as input ad then ouputs result sets with general information
about the object, and also information about columns, indexes, constraints and more.

sp_columns: returns information about columns in an object. For example, the following
code returns detailed information about the Orders table.

sp_helpconstraint: returns information about constraints in an object 
*/

EXEC sys.sp_tables;

EXEC sys.sp_help
	@objname = N'Sales.Orders';

EXEC sys.sp_columns
	@table_name = 'Orders',
	@table_owner = 'Sales';

EXEC sys.sp_helpconstraint
	@objname = 'Sales.Orders';


/* 
	SERVERPROPERTY

This returns the requested property of the current instance. For example, the below code
returns the product level (such as RTM, SP1, SP2, and so on) of the current database.

	DATABASEPROPERTYEX

This returns the requested peoperty of the database name. The below code returns the collation
of the TSQLV4 database.

	OBJECTPROPERTY

THis returns the requested property of the specified object name. The below indicates 
whether the Orders table has a primary key.

	COLUMNPROPERTY

This returns the requested property of the specified column. The below indicates whether
the shipcountry column in the Orders table is nullable:
*/

SELECT 
	SERVERPROPERTY('ProductLevel');

SELECT 
	DATABASEPROPERTYEX('TSQLV4', 'Collation');

SELECT
	OBJECTPROPERTY(OBJECT_ID('Sales.Orders'), 'TableHasPrimaryKey');

SELECT
	COLUMNPROPERTY(OBJECT_ID('Sales.Orders'), 'shipcountry', 'AllowsNull');

