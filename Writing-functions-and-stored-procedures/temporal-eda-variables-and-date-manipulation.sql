/* Temporal EDA, Variables & Date Manipulation	*/

-- Compute for transaction per day

SELECT
  CONVERT(DATE, StartDate) as StartDate,
  COUNT(ID) as CountOfRows 
FROM CapitalBikeShare 
GROUP BY CONVERT(DATE, StartDate)
ORDER BY CONVERT(DATE, StartDate);

-- Check for transactions with seconds/ no seconds

SELECT
	COUNT(ID) AS Count,
    "StartDate" = CASE WHEN DATEPART(SECOND, StartDate) = 0 THEN 'SECONDS = 0'
					   WHEN DATEPART(SECOND, StartDate) > 0 THEN 'SECONDS > 0' END
FROM CapitalBikeShare
GROUP BY
	CASE WHEN DATEPART(SECOND, StartDate) = 0 THEN 'SECONDS = 0'
		 WHEN DATEPART(SECOND, StartDate) > 0 THEN 'SECONDS > 0' END;

-- Which day of the week is busiest?

SELECT
	DATENAME(WEEKDAY, StartDate) as DayOfWeek,
	SUM(DATEDIFF(SECOND, StartDate, EndDate))/ 3600 as TotalTripHours 
FROM CapitalBikeShare 
GROUP BY DATENAME(WEEKDAY, StartDate)
ORDER BY TotalTripHours DESC;

/*
Find the outliers! Do you wonder if there were any individual Saturday outliers that 
contributed to this?
*/
SELECT
  	SUM(DATEDIFF(SECOND, StartDate, EndDate))/ 3600 AS TotalRideHours,
  	CONVERT(DATE, StartDate) AS DateOnly,
  	DATENAME(WEEKDAY, CONVERT(DATE, StartDate)) AS DayOfWeek 
FROM CapitalBikeShare
WHERE DATENAME(WEEKDAY, StartDate) = 'Saturday' 
GROUP BY CONVERT(DATE, StartDate);

-- Using DECLARE & CAST

DECLARE @ShiftStartTime AS time = '08:00 AM';
DECLARE @StartDate AS date;
SET 
	@StartDate = (
    	SELECT TOP 1 StartDate 
    	FROM CapitalBikeShare 
    	ORDER BY StartDate ASC
		);
DECLARE @ShiftStartDateTime AS datetime;
SET @ShiftStartDateTime = CAST(@StartDate AS datetime) + CAST(@ShiftStartTime AS datetime);

SELECT @ShiftStartDateTime;

-- DECLARE a TABLE

DECLARE @Shifts TABLE(
	StartDateTime DATETIME2,
	EndDateTime DATETIME2)
INSERT INTO @Shifts (StartDateTime, EndDateTime)
	SELECT '3/1/2018 8:00 AM', '3/1/2018 4:00 PM';

SELECT * 
FROM @Shifts;

-- INSERT INTO @TABLE

-- Declare @RideDates
DECLARE @RideDates TABLE(
	RideStart DATE, 
    RideEnd DATE)

INSERT INTO @RideDates(RideStart, RideEnd)
SELECT DISTINCT
	CAST(StartDate as date),
    CAST(EndDate as date) 
FROM CapitalBikeShare;

SELECT * 
FROM @RideDates

-- Find the first day of the week
SELECT DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0);

-- Find the first day of the current month
SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)