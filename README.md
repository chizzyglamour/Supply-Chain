# Revolutionizing Supply Chain with SQL-Driven Inventory Optimization

## Table of Contents

- [Project Overview](#project-overview)
- [Data Analysis](#data-analysis)
- [Recommendations](#recommendations)

### Project Overview
---

TechElectro Inc., a global leader in consumer electronics, offers a diverse range of products, 
including smartphones and home appliances. Despite its global reach, the company faces inventory 
management challenges, such as overstocking, understocking, and reduced customer satisfaction due to stock issues.
The project aims to address these inefficiencies to enhance operational performance and customer loyalty.

### Data Source
---

1. Sales Data: 
   Contains details of product sales, including product ID, sale date, units sold, and cost per unit.  

2. Product Data:  
   Includes product details like product ID, category, and promotion status.  

3. External Factors:  
   Provides external factors influencing sales, such as GDP, inflation rate, and seasonal index.

### Tools
---
- MySQL
  - [Download here](htpps://www.mysql.com)

### Data Cleaning/Preparation
---

In the initial phase of this project, the following steps were carried out to prepare the data:

1. Data loading and Exploration.
2. Understanding datasets structures.

The Data Cleaning phase includes:
1. Changing to the right type of data.
2. Handling missing values.
3. Dealing with duplicates.

### Data Integration
---

This involved combining relevant datasets SQL joins (`INNER JOIN`, `LEFT JOIN`, etc.) for further analysis

- combination of sales_data and product_data
- combination of sales_product_data and external factors

### Exploratory Data Analysis (EDA)
---

 Utilized MySQL for EDA, conducting advanced analytics and statistical analysis to explore data patterns, correlations, and descriptive statistics without relying on data visualization.

 - What is the average sales for each product?
 - What is the median stock for each product?
 - What is the product performance metrics for each product?
 - Calculate the frequency of stockouts for high-demand products
 - Are there any seasonality patterns in the sales data that could inform stock levels?



### Data Analysis
---

In this phase we carry out inventory optimization which aims to ensure that the right amount of stock is maintained to meet customer demand while minimizing holding costs and potential stockouts. 
To achieve this, the following steps were taken: 

 - Determine the optimal reorder point for each product based on historical sales data and external factors
 - Use SQL window functions to analyze sales trends.
 - Calculate safety stock levels based on sales variability and lead time
 - Analyse Overstock and Understock Situations
 - Monitor and Adjust:(stored procedures)

### Results/Findings
---

1. Inventory Discrepancies: The initial stages of the analysis revealed significant discrepancies in inventory levels, with instances of both overstocking and understocking.
 These inconsistencies were contributing to capital inefficiencies and customer dissatisfaction.

2. Sales Trends and External Influences: The analysis indicated that sales trends were notably influenced by various external factors.
   Recognizing these patterns provides an opportunity to forecast demand more accurately.

3. Suboptimal Inventory Levels: Through the inventory optimization analysis, it was evident that the existing inventory levels were not optimized for current sales trends.
    Products was identified that had either close excess inventory.

### Recommendations
---

1. Implement Dynamic Inventory Management: The company should transition from a static to a dynamic inventory management system,
   adjusting inventory levels based on real-time sales trends, seasonality, and external factors.

2. Optimize Reorder Points and Safety Stocks: Utilize the reorder points and safety stocks calculated during the analysis to
    minimize stockouts and reduce excess inventory. Regularly review these metrics to ensure they align with current market conditions.

3. Enhance Pricing Strategies: Conduct a thorough review of product pricing strategies, especially for products identified as unprofitable. Consider factors such as
    competitor pricing, market demand, and product acquisition costs.

4. Reduce Overstock: Identify products that are consistently overstocked and take steps to reduce their inventory levels. This
   could include promotional sales, discounts, or even discontinuing products with low sales performance.

5. Establish a Feedback Loop: Develop a systematic approach to collect and analyze feedback from various stakeholders. Use
   this feedback for continuous improvement and alignment with business objectives.

6. Regular Monitoring and Adjustments: Adopt a proactive approach to inventory management by regularly monitoring key
     metrics and making necessary adjustments to inventory levels, order quantities, and safety stocks.

By addressing these areas, TechElectro Inc. can significantly improve its inventory management system, leading to increased
operational efficiency, reduced costs, and enhanced customer satisfaction.

 







