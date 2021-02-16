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
 T-SQL supports the four obvious arithmetic operators: +, –, *, and /. It also supports the %
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
3. + (Positive), – (Negative), + (Addition), + (Concatenation), – (Subtraction)
4. =, >, <, >=, <=, <>, !=, !>, !< (Comparison operators)
5. NOT
6. AND
7. BETWEEN, IN, LIKE, OR
8. = (Assignment)

*/

/*The query returns orders that were either “placed by customer 1 and handled by employees
1, 3, or 5” or “placed by customer 85 and handled by employees 2, 4, or 6.”*/

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
FROm dbo.EmployeeCVs;  -- Invalid table. Just for illustration.

