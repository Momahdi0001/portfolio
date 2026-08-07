/* 1) فروش هر کالا در هر فروشگاه را در سطح روز تجمیع می‌کنیم
      (تا اگر در یک روز چند سفارش/آیتم بوده، آن روز فقط یک‌بار شمرده شود) */
WITH DailySales AS
(
    SELECT
        o.store_id,
        oi.product_id,
        CAST(o.order_date AS date) AS order_day,
        SUM(oi.quantity) AS qty_sold_in_day
    FROM sales.orders       AS o
    INNER JOIN sales.order_items AS oi
        ON oi.order_id = o.order_id
    GROUP BY
        o.store_id,
        oi.product_id,
        CAST(o.order_date AS date)
),

/* 2) مجموع فروش و تعداد روزهایی که فروش رخ داده (بازه/تعداد روز فروش) */
SalesAgg AS
(
    SELECT
        store_id,
        product_id,
        SUM(qty_sold_in_day) AS total_qty_sold,
        COUNT(*)             AS sales_days   
    FROM DailySales
    GROUP BY
        store_id,
        product_id
),

/* 3) سرعت فروش روزانه */
SalesRate AS
(
    SELECT
        store_id,
        product_id,
        CAST(total_qty_sold AS decimal(18,6)) / NULLIF(sales_days, 0) AS daily_sales_rate
    FROM SalesAgg
),

/* 4) موجودی هر کالا در هر فروشگاه */
Stock AS
(
    SELECT
        store_id,
        product_id,
        quantity AS on_hand
    FROM production.stocks
)

/* 5) ماندگاری = موجودی / سرعت فروش روزانه  و رُند به پایین */
SELECT
    st.store_id,
    st.product_id,
    FLOOR( CAST(st.on_hand AS decimal(18,6)) / NULLIF(sr.daily_sales_rate, 0) ) AS days_of_inventory
FROM Stock AS st
LEFT JOIN SalesRate AS sr
    ON sr.store_id = st.store_id
   AND sr.product_id = st.product_id
ORDER BY
    st.store_id,
    st.product_id;
