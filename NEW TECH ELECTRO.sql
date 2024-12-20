-- preliminaries- creation of Schema/Database
CREATE SCHEMA TechElectro;
SHOW DATABASES;
USE TechElectro;

-- DATA EXPLORATION
SELECT * FROM external_factors LIMIT 10;
SELECT * FROM product_data LIMIT 10;
SELECT * FROM sales_data LIMIT 10;

-- Understanding the structure of the datasets
SHOW COLUMNS FROM external_factors;
DESCRIBE product_data;
DESC sales_data;

-- DATA CLEANING
-- Changing to the right type for all columns
-- External data should be like this ideally
-- SalesDate DATE, GDP DECIMAL (15,2), InflationRate DECIMAL (5, 2), SeasonalFactor DECIMAL (5, 2), 

ALTER TABLE external_factors
ADD COLUMN New_Sales_Date DATE;
SET SQL_SAFE_UPDATES = 0; -- turning off safe updates
UPDATE external_factors
SET New_Sales_Date = STR_TO_DATE(`Sales Date`,'%d/%m/%Y');
ALTER TABLE external_factors
DROP COLUMN `Sales Date`;
ALTER TABLE external_factors
CHANGE COLUMN New_Sales_Date Sales_Date DATE; 

ALTER TABLE external_factors
MODIFY COLUMN GDP DECIMAL(15, 2);

ALTER TABLE external_factors
MODIFY COLUMN `Inflation Rate` DECIMAL(5, 2);

ALTER TABLE external_factors
MODIFY COLUMN `Seasonal Factor` DECIMAL(5, 2);

SHOW COLUMNS FROM external_factors;

-- Product data
-- Product_ID INT NOT NULL, Product_Category TEXT, Promotions ENUM( 'yes', 'no');

ALTER TABLE product_data
ADD COLUMN NewPromotions ENUM('yes', 'no');
UPDATE product_data
SET NewPromotions = CASE
WHEN Promotions ='yes' THEN 'yes'
WHEN Promotions = 'no' THEN 'no'
ELSE NULL 
END;
ALTER TABLE product_data
DROP COLUMN Promotions;

ALTER TABLE product_data
CHANGE COLUMN NewPromotions Promotions ENUM('yes', 'no');


-- Sales data
-- Product ID INT NOT NULL, Sales_Date DATE, Inventory_Quantity INT, Product_Cost DECIMAL(10, 2)

ALTER TABLE sales_data
ADD COLUMN New_Sales_Date DATE;
UPDATE sales_data
SET New_Sales_Date = STR_TO_DATE(`Sales Date`,'%d/%m/%Y');

ALTER TABLE sales_data
DROP COLUMN `Sales Date`;

ALTER TABLE sales_data
CHANGE COLUMN New_Sales_Date Sales_Date DATE;

ALTER TABLE sales_data
MODIFY COLUMN `Product Cost` DECIMAL(10, 2);
DESC sales_data;

-- Identifying missing values using IS NULL functions
-- External_factors
SELECT
SUM(CASE WHEN Sales_Date IS NULL THEN 1 ELSE 0 END) AS missing_sales_date,
SUM(CASE WHEN GDP IS NULL THEN 1 ELSE 0 END) AS missing_gdp,
SUM(CASE WHEN `Inflation Rate` IS NULL THEN 1 ELSE 0 END) AS missing_inflation_rate,
SUM(CASE WHEN `Seasonal Factor` IS NULL THEN 1 ELSE 0 END) AS missing_seasonal_factor
FROM external_factors;

-- product data
SELECT
SUM(CASE WHEN `Product ID` IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
SUM(CASE WHEN `Product Category` IS NULL THEN 1 ELSE 0 END) AS missing_product_category,
SUM(CASE WHEN `Promotions` IS NULL THEN 1 ELSE 0 END) AS missing_promotions
FROM product_data;

-- sales data 
SELECT
SUM(CASE WHEN `Product ID` IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
SUM(CASE WHEN Sales_Date IS NULL THEN 1 ELSE 0 END) AS missing_Sales_Date,
SUM(CASE WHEN `Product Cost` IS NULL THEN 1 ELSE 0 END) AS missing_product_cost,
SUM(CASE WHEN `Inventory Quantity` IS NULL THEN 1 ELSE 0 END) AS missing_inventory_quantity
FROM sales_data;

-- checking for duplicates using 'GROUP BY' and 'HAVING' clauses and remove them if necessary
-- external_factors
SELECT Sales_Date, COUNT(*) AS count
FROM external_factors
GROUP BY Sales_Date
HAVING count > 1;

-- Duplicate Count
SELECT COUNT(*) FROM
(SELECT Sales_Date, COUNT(*) AS count
FROM external_factors
GROUP BY Sales_Date
HAVING count > 1) AS dup;

-- product data
SELECT `Product ID`,COUNT(*) `Product Category`,COUNT(*) AS count
FROM product_data
GROUP BY `Product ID` 
HAVING count > 1;

SELECT COUNT(*) FROM
(SELECT `Product ID`,COUNT(*) `Product Category`,COUNT(*) AS count
FROM product_data
GROUP BY `Product ID` 
HAVING count > 1) AS dup;

-- sales data
SELECT `Product ID`,count(*) `Sales_Date`, COUNT(*) AS count
FROM sales_data
GROUP BY `Product ID`, `Sales_Date`
HAVING count > 1;

-- Dealing with duplicates
-- External_factors
DELETE e1 FROM external_factors e1
INNER JOIN (
SELECT Sales_Date,
ROW_NUMBER() OVER (PARTITION BY Sales_Date ORDER BY Sales_Date) as rn
FROM external_factors
) e2 ON e1.Sales_Date = e2.Sales_Date
WHERE e2.rn > 1;
SELECT COUNT(*) FROM external_factors;

-- product data

DELETE p1 FROM product_data p1
INNER JOIN (
SELECT `Product ID`,
ROW_NUMBER() OVER (PARTITION BY `Product ID` ORDER BY `Product ID`) as rn
FROM product_data
) p2 ON p1.`Product ID` = p2.`Product ID`
WHERE p2.rn > 1;
SELECT COUNT(*) FROM product_data;

-- Data Integration
-- combine sales data amd product data first
CREATE VIEW sales_product_data AS 
SELECT 
s. `Product ID`,
s. Sales_Date,
s. `Inventory Quantity`,
s. `Product Cost`,
p. `Product Category`,
p. `Promotions`
FROM sales_data s 
JOIN product_data p ON s. `Product ID` = p.`Product ID`;


-- Sales-product_data and external_factors
CREATE VIEW Inventory_data AS
SELECT
sp.`Product ID`,
sp. Sales_Date,
sp. `Inventory Quantity`,
sp. `Product Cost`,
sp. `Product Category`,
sp. `Promotions`,
e. `GDP`,
e. `Inflation Rate`,
e. `Seasonal Factor`
FROM sales_product_data sp
LEFT JOIN external_factors e
ON sp.Sales_Date = e.Sales_Date;

-- DESCRIPTIVE ANALYSIS
-- BASIC STATISTICS
-- Average sales (calculated as the product of " inventory quantity * product cost)

SELECT `Product ID`,
ROUND(AVG(`Inventory Quantity`* `Product Cost`),2) as avg_sales
FROM inventory_data
GROUP BY `Product ID` 
ORDER BY avg_sales DESC;

-- median stock levels(i.e., "Inventory Quantity").
WITH cte_row_numbers AS (
    SELECT 
        `Product ID`, 
        `Inventory Quantity`,
        ROW_NUMBER() OVER (PARTITION BY `Product ID` ORDER BY `Inventory Quantity`) AS row_num_asc,
        ROW_NUMBER() OVER (PARTITION BY `Product ID` ORDER BY `Inventory Quantity` DESC) AS row_num_desc
    FROM 
        inventory_data
),
cte_filtered_median AS (
    SELECT 
        `Product ID`, 
        `Inventory Quantity`
    FROM 
        cte_row_numbers
    WHERE 
        row_num_asc IN (row_num_desc, row_num_desc - 1, row_num_desc + 1)
)
SELECT 
    `Product ID`, 
    AVG(`Inventory Quantity`) AS median_stock
FROM 
    cte_filtered_median
GROUP BY 
    `Product ID`;

-- Product performsance metrics (total sales per product).
SELECT `Product ID`,
ROUND(SUM(`Inventory Quantity`* `Product Cost`)) as total_sales
FROM inventory_data
GROUP BY `Product ID` 
ORDER BY total_sales DESC;

-- Identify high-demand products based on average sales
	
WITH HighDemandProducts AS (
    SELECT `Product ID`, AVG(`Inventory Quantity`) as avg_sales
    FROM Inventory_data
    GROUP BY `Product ID`
    HAVING avg_sales > (
        SELECT AVG(`Inventory Quantity`) * 0.95 FROM Sales_data  -- This approximates the top 5% threshold
    )
)

-- Calculate stockout frequency for high-demand products
SELECT s.`Product ID`,
       COUNT(*) as stockout_frequency
FROM Inventory_data s
WHERE s.`Product ID` IN (SELECT `Product ID` FROM HighDemandProducts)
AND s.`Inventory Quantity` = 0
GROUP BY s.`Product ID`;


-- Influence of external factors
-- GDP

SELECT `Product ID`,
AVG(CASE WHEN `GDP` > 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_positive_gdp,
AVG(CASE WHEN `GDP` <= 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_non_positive_gdp
FROM inventory_data
GROUP BY `Product ID`
HAVING avg_sales_positive_gdp IS NOT NULL;

-- Inflation
SELECT `Product ID`,
AVG(CASE WHEN `Inflation Rate` > 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_positive_inflation,
AVG(CASE WHEN `Inflation Rate` <= 0 THEN `Inventory Quantity` ELSE NULL END) AS avg_sales_non_positive_inflation
FROM inventory_data
GROUP BY `Product ID`
HAVING avg_sales_positive_inflation IS NOT NULL;

-- OPTIMIZING INVENTORY
--  Determine the optimal reorder point for each product based on historical sales data and external factors
-- Reorder point = lead time + safety stock
-- Lead time demand = rolling average sales * lead time
-- Safety stock = z* lead time^-2 * standard deviation of demand
-- Z= 1.645
-- A constant lead time of 7 days for all products.
-- We aim for a 95% service level.
WITH 
DailySales AS (
    SELECT 
        `Product ID`,
        Sales_Date,
        `Inventory Quantity` * `Product Cost` AS daily_sales,
        POW(
            `Inventory Quantity` * `Product Cost` - 
            AVG(`Inventory Quantity` * `Product Cost`) OVER (
                PARTITION BY `Product ID` 
                ORDER BY Sales_Date 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 
            2
        ) AS squared_diff
    FROM Inventory_data
),
RollingCalculations AS (
    SELECT 
        `Product ID`,
        AVG(daily_sales) OVER (
            PARTITION BY `Product ID` 
            ORDER BY Sales_Date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_sales,
        AVG(squared_diff) OVER (
            PARTITION BY `Product ID` 
            ORDER BY Sales_Date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_variance
    FROM DailySales
),
InventoryAggregates AS (
    SELECT 
        `Product ID`,
        AVG(rolling_avg_sales) AS avg_rolling_sales,
        AVG(rolling_variance) AS avg_rolling_variance
    FROM RollingCalculations
    GROUP BY `Product ID`
)
SELECT 
    `Product ID`,
    avg_rolling_sales * 7 AS lead_time_demand,
    1.645 * (avg_rolling_variance * 7) AS safety_stock,
    (avg_rolling_sales * 7) + (1.645 * (avg_rolling_variance * 7)) AS reorder_point
FROM InventoryAggregates;



-- Create the inventory_optimization table
CREATE TABLE inventory_optimization ( Product_ID INT PRIMARY KEY,
Reorder_Point DOUBLE
);

-- Step 2: Create the stored procedure to Recalculate Reorder Point
DELIMITER //
CREATE PROCEDURE RecalculationsReorderPoint(ProductID INT)
BEGIN
	DECLARE avgRollingSales DOUBLE;
    DECLARE avgRollingVariance DOUBLE;
    DECLARE LeadTimeDemand DOUBLE;
    DECLARE safetyStock DOUBLE;
    DECLARE reorderPoint DOUBLE;
    
SELECT 
	AVG(rolling_avg_sales), AVG(rolling_variance) INTO avgRollingSales, avgRollingVariance
FROM (
	SELECT `Product ID`,
		AVG(daily_sales) OVER (PARTITION BY `Product ID` ORDER BY Sales_Date 
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_sales,
		AVG(squared_diff) OVER (PARTITION BY `Product ID` ORDER BY Sales_Date
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_variance
FROM (
				SELECT `Product ID`,
						Sales_Date,
                        `Inventory Quantity` *
                        `Product Cost`as daily_sales, 
	(`Inventory Quantity` * `Product Cost` - AVG(`Inventory Quantity`* `Product Cost`) OVER 
    (PARTITION BY `Product ID` ORDER BY Sales_Date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) * (`Inventory Quantity` * 
    `Product Cost`- AVG(`Inventory Quantity` * `Product Cost`) 
    OVER (PARTITION BY `Product ID` ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW))
    as squared_diff
    FROM inventory_data
    ) InnerDerived
    ) OuterDerived;
    SET LeadTimeDemand = avgRollingSales * 7;
    SET reorderPoint = LeadTimeDemand + safetyStock;
INSERT INTO inventory_optimization (Product_ID, Reorder_Point)
	VALUES (productID, reorderPoint)
ON DUPLICATE KEY UPDATE Recorder_Point = reorderPoint;
END //
DELIMITER ;

    CREATE TABLE Inventory_table AS SELECT * FROM inventory_data;
    -- Step 4: create the trigger
    DELIMITER //
    CREATE TRIGGER AfterInsertUnifiedTable
    After INSERT ON Inventory_table
    FOR EACH ROW
    BEGIN
    CALL RecalculateReorderPoint(NEW.`Product ID`); 
    END //
    DELIMITER ;
    
-- Calculate rolling average sales
WITH RollingSales AS (
    SELECT  
        `Product ID`,
        Sales_Date,
        AVG(`Inventory Quantity` * `Product Cost`) OVER (
            PARTITION BY `Product ID` 
            ORDER BY Sales_Date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_sales
    FROM Inventory_table
),

-- Calculate the number of days a product was out of stock
StockoutDays AS (
    SELECT 
        `Product ID`,
        COUNT(*) AS stockout_days
    FROM Inventory_table
    WHERE `Inventory Quantity` = 0
    GROUP BY `Product ID`
)

-- Final query to join and aggregate data
SELECT 
    f.`Product ID`,
    AVG(f.`Inventory Quantity` * f.`Product Cost`) AS avg_inventory_value,
    AVG(rs.rolling_avg_sales) AS avg_rolling_sales,
    COALESCE(sd.stockout_days, 0) AS stockout_days
FROM Inventory_table f
JOIN RollingSales rs 
    ON f.`Product ID` = rs.`Product ID` 
    AND f.Sales_Date = rs.Sales_Date
LEFT JOIN StockoutDays sd 
    ON f.`Product ID` = sd.`Product ID`
GROUP BY f.`Product ID`, sd.stockout_days;

-- Monitor and adjust
	-- MonitOr inventory levels
    DELIMITER //
    CREATE PROCEDURE MonitorInventoryLevelss()
    BEGIN
    SELECT `Product ID`, AVG(`Inventory Quantity`) as AvgInventory
    FROM Inventory_table
    GROUP BY `Product ID`
    ORDER BY AvgInventory DESC;
    END//
    DELIMITER ;
    
    -- Monitor sales trend
    DELIMITER //
    CREATE PROCEDURE MonitorSalesTrend()
    BEGIN
    SELECT `Product ID`, Sales_Date,
    AVG(`Inventory Quantity` * `Product Cost`) OVER (PARTITION BY `Product ID` ORDER BY 
			Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as RollingAvgSales
				FROM inventory_table
                ORDER BY `Product ID`, Sales_Date;
			END//
            DELIMITER ;
            
-- Monitor Stockout frequencies
DELIMITER //
CREATE PROCEDURE MonitorStockouts()
BEGIN
SELECT `Product ID`, COUNT(*) as StockoutDays
FROM inventory_table
	WHERE `Inventory Quantity` = 0
    GROUP BY `Product ID`
    ORDER BY StockoutDays DESC;
    END//
    DELIMITER ;
    
-- FEEDBACK LOOP

-- Feedback Loop Establishment
-- Feedback Portal: Develop an online for stakeholders to easily submit feedback on inventory performance and challenges.
-- Review Meetings; Organize periodic sessions to discuss inventory system performance and gather direct insights.
-- System Monitoring: Use established SQL procedures to track system metrics, with deviations from expectations flagged for review

-- Refinenent Based on Feedback:
-- Feedback Analysis: Regularly compile and scrutinize feedback to identify reccurring themes or pressing
-- Action Implementation: Priotize and act on the feedback to adjust reorder point, safety stock levels or overall processes.
-- Change Communication: Inform stakeholders about changes, underscoring the value of their feedback and ensuring transperency.alter

-- GENERAL INSIGHTS

-- Inventory Disperancies: The initial stages of the analysis revealed significant dsiperancies in inventory levels, with instances with both overstocking and understocking.
 -- These inconsistencies were contributing to capital ineffiencies and customer dissatisfaction.

-- Sales Trends and External Influences: The analysis indicated that sales trends were notably influenced by various external factors.
  -- Recognizing these patterns provides an opportunity to forecast demand accurately. 
  
-- Suboptimal Inventory Levels: Through the inventory optimization analysis, it was evident that the inventory levels were optimized for current sales trend. 
-- 	product was identified that either close excess inventory.



-- Recommendations:

-- 1. Implement Dynamic Inventory Management: The company should transition from a static to a dynamic inventory management system,
-- adjusting inventory levels based on real-time sales trends, seasonality and external factors.alter

-- 2. Optimize Reorder Points and Safety Stocks: Utilize the reorder points and safety stocks calculated during the analysis to minimize stockouts and reduce excess inventory.
 -- Regualrly review these metrics to ensure they align with current market conditions.
 
 -- 3. Enhance Pricing Stratgeies: Conduct a thorough review of product pricing strategies, especially for products  identified as unprofitable. 
  -- Consider factors such as competitor pricing, market demand, and product acquisition costs. 
  
-- 4. Reduce Overstock: Identify products that are consistently overstocked and take steps to reduce their inventory levels.
 -- This could include promotional sales, discounts, or even discontinuing products with low sales performance.
 
-- 5. Establish a Feedback Loop: Develop a systematic approach to collect and analyze feedback from various stakeholders.
 -- Use this feedback for continous improvement and alignment with business objectives.
 
-- 6. Regular Monitoring and Adjustments: Adopt a proactive approach to inventory management by regularly monitoring key metrics
 -- and making necessary adjustments to inventory levels, order quantities, and safety stocks.