/* SCALAR USER-DEFINED FUNCTION	*/

/*
Routines that can accept input parameters, perform an action and return result
(either single scalar value/ table)

*/

CREATE FUNCTION GetTomorrow()
	RETURNS date AS BEGIN
RETURN (SELECT DATEADD(day, 1, GETDATE()))
END;

SELECT GetTomorrow();

-- Scalar UDF with one parameter

CREATE FUNCTION GetRideHrsOneDay (@DateParm DATE)
	RETURNS numeric AS BEGIN
RETURN (
	SELECT
		SUM(DATEDIFF(SECOND, PickupDate, DropoffDate))/ 3600
	FROM YellowTripData
	WHERE CONVERT(DATE, PickupDate) = @DateParm
) END;

-- Scalar UDF with two parameters

CREATE FUNCTION GetRideHrsDateRange (@StartDateParm DATETIME, @EndDateParm DATETIME)
	RETURNS numeric AS BEGIN 
RETURN (
	SELECT 
		SUM(DATEDIFF(SECOND, PickupDate, DropoffDate))/ 3600
	FROM YellowTripData
	WHERE PickupDate > @StartDateParm AND DropoffDate < @EndDateParm
) END;

-- WHat was yesterday?

CREATE FUNCTION GetYesterday()
	RETURNS date AS BEGIN
RETURN
    (
	SELECT DATEADD(day, -1, GETDATE())
) END;

-- One-in-one-out

-- Create SumRideHrsSingleDay
CREATE FUNCTION SumRideHrsSingleDay (@DateParm date)
	RETURNS numeric AS BEGIN
RETURN
-- Add the difference between StartDate and EndDate
	(
	SELECT SUM(DATEDIFF(second, StartDate, EndDate))/3600
	FROM CapitalBikeShare
	WHERE CAST(StartDate AS date) = @DateParm
) END;

-- Multiple inputs one output

-- Create the function
CREATE FUNCTION SumRideHrsDateRange (@StartDateParm DATETIME, @EndDateParm DATETIME)
	RETURNS numeric AS BEGIN
RETURN
	(
	SELECT SUM(DATEDIFF(second, StartDate, EndDate))/3600
	FROM CapitalBikeShare
	WHERE StartDate > @StartDateParm and StartDate < @EndDateParm
) END;


/*
	TABLE-VALUED FUNCTIONS

# BEGIN-END block is not NECESSARY for TVFs
# BEGIN-END block is NECESSARY for multi-statement TVFs

	INline TVFs

# RETURN results of SELECT # Table column names in SELECT # No table variable
# No BEGIN-END block needed # No INSERT # Faster performance

	MSTVFs

# Must declare a table variable to be returned # BEGIN-END block is required
# INSERT data into TABLE variable # REturn last statement within BEGIN-END block

*/

-- In-line TVFs

CREATE FUNCTION SumLocationStats (@StartDate AS datetime = '1/1/2017')
	RETURNS TABLE AS 
RETURN
SELECT
	PULocationID AS PickupLocation,
	COUNT(ID) AS RideCount,
	SUM(TripDistance) AS TotalTripDistance
FROM YellowTripData
WHERE CAST(PickupDate AS Date) = @StartDate
GROUP BY PULocationID;

-- Multi-statement TVFs ()

CREATE FUNCTION CountTripAvgDareDay (@Month char(2), @Year char(4))
RETURNS @TripCountAvgFare TABLE (DropoffDate date, TripCount int, AvgFare numeric)
AS 
BEGIN 
INSERT INTO @TripCountAvgFare
SELECT
	CAST(DropoffDate AS date),
	COUNT(ID),
	AVG(FareAmount) AS AvgFareAmt
FROM YellowTripData
WHERE 
	DATEPART(MONTH, DropoffDate) = @Month AND DATEPART(YEAR, DROPOFFDATE) = @Year
GROUP BY CAST(DropoffDate AS date)
RETURN END

-- Inline TVFs

-- Create the function
CREATE FUNCTION SumStationStats(@StartDate AS DATETIME)
RETURNS TABLE
AS
RETURN
SELECT
	StartStation,
	COUNT(ID) AS RideCount,
    SUM(Duration) AS TotalDuration
FROM CapitalBikeShare
WHERE CAST(StartDate as Date) = @StartDate
GROUP BY StartStation;

-- MSTVF

-- Create the function
CREATE FUNCTION CountTripAvgDuration (@Month CHAR(2), @Year CHAR(4))
RETURNS @DailyTripStats TABLE(
	TripDate	date,
	TripCount	int,
	AvgDuration	numeric)
AS
BEGIN
INSERT INTO @DailyTripStats
SELECT
	CAST(StartDate AS date),
    COUNT(ID),
    AVG(Duration)
FROM CapitalBikeShare
WHERE
	DATEPART(month, StartDate) = @Month AND
    DATEPART(year, StartDate) = @Year
GROUP BY CAST(StartDate AS date)
-- Return
RETURN
END;

-- Execute SCALAR with SELECT

DECLARE @BeginDate AS date = '3/1/2018'
DECLARE @EndDate AS date = '3/10/2018' 
SELECT
  @BeginDate AS BeginDate,
  @EndDate AS EndDate,
  dbo.SumRideHrsDateRange(@BeginDate, @EndDate) AS TotalRideHrs;

-- USing EXEC scalar

DECLARE @RideHrs AS numeric
EXEC @RideHrs = dbo.SumRideHrsSingleDay @DateParm = '3/5/2018' 
SELECT 
  'Total Ride Hours for 3/5/2018:', 
  @RideHrs;

-- Execute TVF into variable

DECLARE @StationStats AS TABLE(
	StartStation nvarchar(100), 
	RideCount int, 
	TotalDuration numeric)

INSERT INTO @StationStats
SELECT TOP 10 *
FROM dbo.SumStationStats('3/15/2018') 
ORDER BY RideCount DESC;
-- Select all the records from @StationStats
SELECT * 
FROM @StationStats


/*
	MAINTAINING USER-DEFINED FUNCTIONS

Using ALTER FUNCTION keyword
	OR
Using CREATE OR ALTER FUNCTION keyword

DROP FUNCTION -- To delete a function

# To check for determinism

Determinism is used to check if results of the function remain unchanged overtime based
on then same input parameters.

SELECT
	OBJECTPROPERTY(
	OBJECT_ID('dbo.GetTomorrow', 'IDeterministic')


*/

-- Alter with WITH SCHEMABINDING option

-- Update SumStationStats
CREATE OR ALTER FUNCTION dbo.SumStationStats(@EndDate AS date)
RETURNS TABLE WITH SCHEMABINDING
AS
RETURN
SELECT
	StartStation,
    COUNT(ID) AS RideCount,
    SUM(DURATION) AS TotalDuration
FROM dbo.CapitalBikeShare
WHERE CAST(EndDate AS Date) = @EndDate
GROUP BY StartStation;