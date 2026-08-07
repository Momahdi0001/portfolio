/*
شناسایی داده ها و درک  جدول
*/

SELECT SalesOrderID as [شناسه منحصر به فرد سفارش]
	,OrderDate as [تاریخ ثبت سفارش]
	,CustomerID as [شناسه مشتری]
	,TotalDue as [مبلغ کل سفارش]
FROM Sales.SalesOrderHeader


SELECT SalesOrderID as[شناسه منحصر به فرد سفارش]
	,SalesOrderDetailID as [شناسه منحصر به فرد هر آیتم]
	,OrderQty as [اعداد محصولات سفارش داده شده]
	,ProductID as [شناسه محصول]
	,UnitPrice as [قیمت هر محصول]
	,LineTotal as [مبلغ کل آیتم]
FROM Sales.SalesOrderDetail

/*
مقدار Recency
به یک “تاریخ امروز” برای مقایسه نیاز دارد
به جای استفاده از 
GETDATE()
از تاریخ آخرین سفارش ثبت‌شده در پایگاه داده به عنوان نقطه مرجع استفاده شده است
  به دلیل اینکه تاریخ هر روز تغییر میکند و ما از مرجعی ثابت استفاده کرده ایم
*/
DECLARE @Today DATE = (SELECT MAX(OrderDate) 
					  FROM Sales.SalesOrderHeader
					  );

/*
یک جدول CTE 
ساخته شده تا مقادیر 
R,F,M
را نمایش دهد
برای محاسبه تازگی اخرین خرید هر مشتری را از مرجع تاریخ که تعریف کردیم کسر کرده
تا خروجی مشخص کند مشتری اخرین خریدش چند روز گذشته بوده است
هر چه تازگی کمتر باشه مشتری فعال تر است
برای محاسبه اینکه مشتری چند بار سفارش ثبت کرده است
پس میگوییم : برای هر مشتری بشمار تعداد شناسه های سفارش فروش اش را
و برای اینکه هر مشتری چندین اقلام در فاکتورش دارد باید از
DISTINCT
استفاده کنیم تا تعداد سفارش های یکتا را بشماریم
محسابه ارزش پولی از جدول SOD
SUM(LineTotal)
جمع کل خرید های مشتری را محاسبه میکند
که مبلع خالص خرید را مشخص میکند و هزینه بسته بندی و... را در نظر نمیگرد
از CAST 
استفاده شده تا خروجی را با دو رفم اعشار گرد شود
*/

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
FROM RFM_Base
ORDER BY CustomerID ASC;

