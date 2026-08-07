/*
محاسبه مقادیر R,F,M
تازگی : محاسبه اختلاف تاریخ مرجع با اخرین تاریخ خرید هر مشتری
فراوانی : شمارش تعداد سفارش های هر مشتری
ارزش پولی: جمع کل مبلغ خرید هر مشتری
برای بهینه نوشتن این بخش به ستون 
SubTotal
توجه میکنیم که برابر جمع 
LineTotal (مبالغ خالص کالاهااز جدول جرییات کالا ها است)
برای رسیدن به بالاترین سطح پرفورمنس نیازی به 
JION
نوشتن بین دو جول نیست 
این کار باعث میشود سرعت در اجرا مصرف بهینه منابع 

*/
DECLARE @Today DATE = (
						SELECT MAX(OrderDate)
						FROM Sales.SalesOrderHeader
				);

WITH RFM_CAL 
	AS (
		SELECT CustomerID
			,DATEDIFF(DAY,MAX(OrderDate),@Today) as Recency
			,COUNT(SalesOrderID) as Frequency
			,CAST(SUM(SubTotal) AS DECIMAL(18, 2)) AS Monetary
		FROM Sales.SalesOrderHeader
		GROUP BY CustomerID
	)
SELECT *
FROM RFM_CAL
ORDER BY CustomerID ASC


/*
-----------------------------------------------------------------------
مقایسه عملکرد دو روش
*/
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO


PRINT '==================================================';
PRINT N' استفاده از JOIN و LineTotal (روش سنتی و سنگین)';
PRINT '==================================================';

DECLARE @Today DATE = (
						SELECT MAX(OrderDate)
						FROM Sales.SalesOrderHeader
				);

WITH RFM_Base AS (
    SELECT SOH.CustomerID
        ,DATEDIFF(day, MAX(SOH.OrderDate), @Today) AS [Recency]
        ,COUNT(DISTINCT SOH.SalesOrderID) AS [Frequency]
        ,CAST(SUM(SOD.LineTotal) AS DECIMAL(18, 2)) AS [Monetary]
        
    FROM Sales.SalesOrderHeader SOH
    JOIN 
		Sales.SalesOrderDetail SOD 
			ON SOH.SalesOrderID = SOD.SalesOrderID
    GROUP BY 
        SOH.CustomerID
)
SELECT * 
INTO #TempMethod1 -- ریختن در جدول موقت برای حذف زمان نمایش در مانیتور
FROM RFM_Base
ORDER BY CustomerID ASC;

GO

PRINT '==================================================';
PRINT N' استفاده از SubTotal (بدون JOIN - بهینه)';
PRINT '==================================================';

DECLARE @Today DATE = (
						SELECT MAX(OrderDate)
						FROM Sales.SalesOrderHeader
				);

WITH RFM_CAL 
	AS (
		SELECT CustomerID
			,DATEDIFF(DAY,MAX(OrderDate),@Today) as Recency
			,COUNT(SalesOrderID) as Frequency
			,CAST(SUM(SubTotal) AS DECIMAL(18, 2)) AS Monetary
		FROM Sales.SalesOrderHeader
		GROUP BY CustomerID
	)
SELECT *
INTO #TempMethod2 -- ریختن در جدول موقت برای حذف زمان نمایش در مانیتور
FROM RFM_CAL
ORDER BY CustomerID ASC


GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
DROP TABLE #TempMethod1;
DROP TABLE #TempMethod2;