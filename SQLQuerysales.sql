--1;-- Business question Wadarta iibak gobalka kast 
select Region ,sum(Sales_amount) as Total_Amount
from dbo.SalesData
Group by region
order by Total_Amount Desc;

--2;-- Business question Sales_Rep ka ugu fiican

select Sales_rep, sum(Sales_Amount)as Total, count(*) as orders
from dbo.SalesData
Group by sales_rep  order by total desc;

-- product category by profit nooc kasta
SELECT Product_Category,
       SUM((Unit_Price - Unit_Cost) * Quantity_Sold) AS Profit
FROM dbo.SalesData
GROUP BY Product_Category
ORDER BY Profit DESC;
--- iibka bil kasta 
SELECT FORMAT(Sale_Date,'yyyy-MM') AS month, SUM(Sales_Amount) AS total
FROM dbo.SalesData
GROUP BY FORMAT(Sale_Date,'yyyy-MM')
ORDER BY month;

-- Online vs Retail

SELECT Sales_Channel, AVG(Sales_Amount) AS avg_sale, AVG(Discount) AS avg_discount
FROM dbo.SalesData 
GROUP BY Sales_Channel;

-- Top 3 sales_rep  (window function)

SELECT * FROM (
  SELECT Region, Sales_Rep, SUM(Sales_Amount) AS total,
         RANK() OVER (PARTITION BY Region ORDER BY SUM(Sales_Amount) DESC) AS rnk
  FROM dbo.SalesData 
  GROUP BY Region, Sales_Rep
)as t WHERE rnk <= 3;


---checking the data is null or negative discount and duplicates

     ---- missiing amount 

SELECT COUNT(*) - COUNT(Sales_Amount) AS missing_amount FROM dbo.SalesData;

              --- missing duplicates

SELECT Product_ID, Sale_Date, Sales_Rep, COUNT(*) AS n
FROM dbo.SalesData
GROUP BY Product_ID, Sale_Date, Sales_Rep
HAVING COUNT(*) > 1;

        --negative discount
SELECT * FROM dbo.SalesData WHERE Sales_Amount <= 0 OR Discount NOT BETWEEN 0 AND 1;

 --- checking duplicates 
 -- Duplicates saf-buuxa (dhammaan columns)
SELECT Product_ID, Sale_Date, Sales_Rep, Region, Sales_Amount, Quantity_Sold,
       Product_Category, Unit_Cost, Unit_Price, Customer_Type, Discount,
       Payment_Method, Sales_Channel, COUNT(*) AS n
FROM dbo.SalesData
GROUP BY Product_ID, Sale_Date, Sales_Rep, Region, Sales_Amount, Quantity_Sold,
         Product_Category, Unit_Cost, Unit_Price, Customer_Type, Discount,
         Payment_Method, Sales_Channel
HAVING COUNT(*) > 1;


----- (MoM growth)
WITH m AS (
  SELECT FORMAT(Sale_Date,'yyyy-MM') AS month, SUM(Sales_Amount) AS total
  FROM dbo.SalesData GROUP BY FORMAT(Sale_Date,'yyyy-MM')
)
SELECT month, total,
       LAG(total) OVER (ORDER BY month) AS prev_month,
       ROUND((total - LAG(total) OVER (ORDER BY month)) * 100.0
             / LAG(total) OVER (ORDER BY month), 1) AS growth_pct
FROM m ORDER BY month;


------ Margin % nooc kasta

SELECT Product_Category,
       SUM((Unit_Price - Unit_Cost) * Quantity_Sold) AS profit,
       ROUND(SUM((Unit_Price - Unit_Cost) * Quantity_Sold) * 100.0
             / SUM(Unit_Price * Quantity_Sold), 1) AS margin_pct
FROM dbo.SalesData GROUP BY Product_Category ORDER BY margin_pct DESC;

----- New vs Returning

SELECT Customer_Type, COUNT(*) AS orders, SUM(Sales_Amount) AS total, AVG(Sales_Amount) AS avg_sale
FROM dbo.SalesData GROUP BY Customer_Type;

-- Discount-ka saamayntiisa
SELECT CASE WHEN Discount < 0.1 THEN '0-9%'
            WHEN Discount < 0.2 THEN '10-19%' ELSE '20%+' END AS discount_band,
       COUNT(*) AS orders, AVG(Sales_Amount) AS avg_sale
FROM dbo.SalesData GROUP BY CASE WHEN Discount < 0.1 THEN '0-9%'
            WHEN Discount < 0.2 THEN '10-19%' ELSE '20%+' END;
