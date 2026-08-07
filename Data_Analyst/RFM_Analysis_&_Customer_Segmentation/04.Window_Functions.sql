/*
هدف ما اختصاص امتیاز به هر یک از شاخص های
R,F,M
است . 
ار تابع NTILE()
برای دیسته بندی داده ها به 4 گروه مساوی تقسیم کرده ایم
منطق امتیاز دهی :
بالاترین امتیاز (4) نشان دهنده بهترین مشتریان است
بنابراین مشتریانی که تازه از اخرین خریدشان میگذرد و بیشتر خرید کرده اند و مجموع خریدشان بیشتر بوده در این مجموعه قرار میگیرند
*/
DECLARE @Today DATE = (
						SELECT MAX(OrderDate)
						FROM Sales.SalesOrderHeader
				);

WITH RFM_BASE 
	AS (
		SELECT CustomerID
			,DATEDIFF(DAY,MAX(OrderDate),@Today) as Recency
			,COUNT(SalesOrderID) as Frequency
			,CAST(SUM(SubTotal) AS DECIMAL(18, 2)) AS Monetary
		FROM Sales.SalesOrderHeader
		GROUP BY CustomerID
	),
	RFM_SCORE
	AS (
		SELECT CustomerID
			,Recency
			,Frequency
			,Monetary

			,NTILE(4) OVER(ORDER BY Recency DESC) AS Recency_Score
			,NTILE(4) OVER (ORDER BY Frequency ASC) AS Frequency_Score
			,NTILE(4) OVER (ORDER BY Monetary ASC) AS Monetary_Score
		FROM RFM_BASE
	)

SELECT 
    CustomerID
    ,Recency
    ,Frequency
    ,Monetary
    ,Recency_Score
    ,Frequency_Score
    ,Monetary_Score
    ,CONCAT(Recency_Score, Frequency_Score, Monetary_Score) AS RFM_Cell
FROM 
    RFM_SCORE;

