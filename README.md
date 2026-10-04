# Sales Analysis: SQL Server + Power BI

An end-to-end analysis of 1,000 sales records (Jan 2023 – Jan 2024): data checks and business questions in **T-SQL**, then an interactive **Power BI** dashboard.

![Dashboard](dashboard.png)

## Business questions

1. Which region sells the most?
2. Who are the top sales reps, overall and within each region?
3. Which product category earns the most profit, and at what margin?
4. How do sales change month to month?
5. Do new and returning customers, channels or discounts change the average sale?

## Data

`SalesData.xlsx`, one table, 1,000 rows, 14 columns:
`Product_ID, Sale_Date, Sales_Rep, Region, Sales_Amount, Quantity_Sold, Product_Category, Unit_Cost, Unit_Price, Customer_Type, Discount, Payment_Method, Sales_Channel, Region_and_Sales_Rep`

Imported into SQL Server as `dbo.SalesData` (database `Sales`).

## Data checks

- No missing values in `Sales_Amount`.
- No fully duplicated rows. Six rows share `Product_ID + Sale_Date + Sales_Rep`, but they differ in amount, quantity and category, so they are separate sales.
- Jan 2024 holds only 3 orders (all on 1 Jan), so it is left out of the monthly trend.

## Key SQL

```sql
-- Sales by region
SELECT Region, SUM(Sales_Amount) AS Total_Amount
FROM dbo.SalesData
GROUP BY Region
ORDER BY Total_Amount DESC;

-- Profit and margin by category
SELECT Product_Category,
       SUM((Unit_Price - Unit_Cost) * Quantity_Sold) AS Profit,
       ROUND(SUM((Unit_Price - Unit_Cost) * Quantity_Sold) * 100.0
             / SUM(Unit_Price * Quantity_Sold), 1) AS Margin_Pct
FROM dbo.SalesData
GROUP BY Product_Category
ORDER BY Profit DESC;

-- Top 3 reps in each region
WITH ranked AS (
    SELECT Region, Sales_Rep, SUM(Sales_Amount) AS Total,
           RANK() OVER (PARTITION BY Region ORDER BY SUM(Sales_Amount) DESC) AS rnk
    FROM dbo.SalesData
    GROUP BY Region, Sales_Rep
)
SELECT * FROM ranked WHERE rnk <= 3 ORDER BY Region, rnk;

-- Month-over-month change
WITH m AS (
    SELECT FORMAT(Sale_Date,'yyyy-MM') AS month, SUM(Sales_Amount) AS total
    FROM dbo.SalesData GROUP BY FORMAT(Sale_Date,'yyyy-MM')
)
SELECT month, total,
       LAG(total) OVER (ORDER BY month) AS prev_month,
       ROUND((total - LAG(total) OVER (ORDER BY month)) * 100.0
             / LAG(total) OVER (ORDER BY month), 1) AS growth_pct
FROM m ORDER BY month;
```

All queries are in [`queries.sql`](queries.sql).

## Dashboard (Power BI)

Five KPI cards (Total Sales, Orders, Avg Sale, Margin %, Best Month), a monthly sales line chart, and bar charts for region, sales rep and profit by category, with Region and Sales_Rep slicers.

Measures used:

```DAX
Total Sales = SUM(SalesData[Sales_Amount])
Orders      = COUNTROWS(SalesData)
Avg Sale    = DIVIDE([Total Sales], [Orders])
Profit      = SUMX(SalesData, (SalesData[Unit_Price] - SalesData[Unit_Cost]) * SalesData[Quantity_Sold])
Revenue     = SUMX(SalesData, SalesData[Unit_Price] * SalesData[Quantity_Sold])
Margin %    = DIVIDE([Profit], [Revenue])
```

## Findings

| Metric | Result |
|---|---|
| Total sales | $5.02M across 1,000 orders |
| Average sale | $5,019 |
| Top region | North, $1.37M (South is lowest at $1.15M, a gap of about 19%) |
| Top rep | David, $1.14M (Charlie is lowest at $0.86M, about a third less) |
| Most profitable category | Furniture, $1.78M |
| Margin | 9–10% in every category |
| Best month | Jan 2023, $476K |

**Takeaways**

- Sales are spread fairly evenly across regions, categories and channels, so no single segment drives the result.
- The clearest gaps are Charlie among reps and South among regions.
- Margins are thin and nearly identical across categories, so pricing and unit cost are the main levers for growth.

## Notes and limits

- `Profit` uses `Unit_Price` and `Unit_Cost`, while `Sales_Amount` is a separate column. The two do not reconcile, so they are not compared directly.
- The data covers one year, so seasonal patterns cannot be confirmed.

## Tools

SQL Server (T-SQL, window functions, CTEs), Power BI (DAX), Excel.

## Files

- `SalesData.xlsx`: source data
- `queries.sql`: all SQL queries
- `SalesDashboard.pbix`: Power BI report
- `dashboard.png`: screenshot of the dashboard
