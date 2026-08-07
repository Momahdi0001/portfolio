/*
خوشه بندی مشتریان به این صورت خواهد بود
ارزش بالا ===4
ارزش متوسط===3
ارزش پایین===2
در معرض خطر===1
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
	),

RFM_Segmentation AS (
    SELECT 
        CustomerID
        ,Recency
        ,Frequency
        ,Monetary
        ,Recency_Score
        ,Frequency_Score
        ,Monetary_Score
        ,CONCAT(Recency_Score, Frequency_Score, Monetary_Score) AS RFM_Cell,
        
        CASE 
            -- ارزش بالا: مشتریانی که اخیراً خرید کرده‌اند، زیاد خرید می‌کنند و پول زیادی خرج می‌کنند
            WHEN Recency_Score >= 3 AND Frequency_Score >= 3 AND Monetary_Score >= 3 THEN N'High Value (ارزش بالا)'
            
            -- در معرض خطر: مشتریانی که قبلاً زیاد خرید می‌کردند اما مدت‌هاست بازنگشته‌اند
            WHEN Recency_Score <= 2 AND Frequency_Score >= 3 THEN N'At Risk (در معرض خطر)'
            
            -- ارزش پایین: مشتریانی که خیلی وقت پیش خرید کرده‌اند و تعداد و مبلغ خریدشان هم کم بوده است
            WHEN Recency_Score <= 2 AND Frequency_Score <= 2 AND Monetary_Score <= 2 THEN N'Low Value (ارزش پایین)'
            
            -- ارزش متوسط: سایر مشتریانی که در دسته‌های افراطی بالا قرار نمی‌گیرند
            ELSE N'Medium Value (ارزش متوسط)'
        END AS Customer_Segment
    FROM 
        RFM_SCORE
)

-- 5. نمایش نهایی داده‌ها (با قابلیت JOIN به جداول مشتری برای اطلاعات دموگرافیک در صورت نیاز)
SELECT 
    S.CustomerID,
    P.FirstName,
    P.LastName,
    S.Customer_Segment,
    S.RFM_Cell,
    S.Recency_Score,
    S.Frequency_Score,
    S.Monetary_Score
FROM 
    RFM_Segmentation AS S
    -- اضافه کردن اطلاعات شخصی مشتریان 
    LEFT JOIN Sales.Customer AS C ON S.CustomerID = C.CustomerID
    LEFT JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
ORDER BY 
    S.Customer_Segment, S.RFM_Cell DESC;

