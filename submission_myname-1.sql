/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
-- Switch to the 'project' database
USE project;

-- Display the first 10 records from the 'customer_t' table
SELECT * FROM customer_t LIMIT 10;

-- Display the first 10 records from the 'order_t' table
SELECT * FROM order_t LIMIT 10;

-- Display the first 10 records from the 'product_t' table
SELECT * FROM product_t LIMIT 10;

-- Display the first 10 records from the 'shipper_t' table
SELECT * FROM shipper_t LIMIT 10;

/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

-- Select the state and count the number of customers for each state
SELECT
    state,
    COUNT(customer_id) AS customers_across_states
FROM
    customer_t
-- Group the results by state
GROUP BY
    state;
    
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter.*/

-- Common Table Expression (CTE) to convert customer feedback into numeric ratings
WITH RatingValues AS (
    -- Selecting numeric ratings based on different types of customer feedback
    SELECT
        CASE customer_feedback
            WHEN 'Very Bad' THEN 1
            WHEN 'Bad' THEN 2
            WHEN 'Okay' THEN 3
            WHEN 'Good' THEN 4
            WHEN 'Very Good' THEN 5
            ELSE NULL -- Handling any other cases with NULL
        END AS numeric_rating,
        quarter_number
    FROM
        order_t
)
-- Select the quarter number and calculate the average numeric rating for each quarter
SELECT
    quarter_number AS quarter,
    AVG(numeric_rating) AS average_rating
FROM
    RatingValues
-- Group the results by quarter number
GROUP BY
    quarter_number
-- Arrange the results in ascending order of quarter number
ORDER BY
    quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
      
-- Common Table Expression (CTE) to calculate the count of different types of customer feedback for each quarter
WITH FeedbackCounts AS (
    SELECT
        quarter_number,
        SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad_count,
        SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad_count,
        SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay_count,
        SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good_count,
        SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good_count,
        COUNT(*) AS total_feedback_count
    FROM
        order_t
    GROUP BY
        quarter_number
)
-- Select the quarter number and calculate the percentage of different types of customer feedback for each quarter
SELECT
    quarter_number AS quarter,
    -- Calculate the percentage of Very Bad feedback
    (very_bad_count / total_feedback_count) * 100 AS percentage_very_bad,
    -- Calculate the percentage of Bad feedback
    (bad_count / total_feedback_count) * 100 AS percentage_bad,
    -- Calculate the percentage of Okay feedback
    (okay_count / total_feedback_count) * 100 AS percentage_okay,
    -- Calculate the percentage of Good feedback
    (good_count / total_feedback_count) * 100 AS percentage_good,
    -- Calculate the percentage of Very Good feedback
    (very_good_count / total_feedback_count) * 100 AS percentage_very_good
FROM
    FeedbackCounts
-- Arrange the results in ascending order of quarter number
ORDER BY
    quarter_number;

-- From the distribution of customer feedback in each quarter, it appears that customers are getting more dissatisfied over time.
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

-- Select the vehicle maker and count the number of distinct customers for each vehicle maker
SELECT
    p.vehicle_maker,
    COUNT(DISTINCT c.customer_id) AS customer_count
FROM
    product_t p
-- Join the 'product_t' table with the 'order_t' table based on the product IDs
JOIN
    order_t o ON p.product_id = o.product_id
-- Join the 'order_t' table with the 'customer_t' table based on the customer IDs
JOIN
    customer_t c ON o.customer_id = c.customer_id
-- Group the results by vehicle maker
GROUP BY
    p.vehicle_maker
-- Arrange the results in descending order of customer count
ORDER BY
    customer_count DESC
-- Limit the results to the top 5 vehicle makers with the highest customer count
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

-- Common Table Expression (CTE) to rank vehicle makers based on customer count within each state
WITH RankedVehicleMakes AS (
    -- Select state, vehicle maker, and count of distinct customers, then assign rank using RANK() window function
    SELECT
        c.state,
        p.vehicle_maker,
        COUNT(DISTINCT o.customer_id) AS customer_count,
        RANK() OVER (PARTITION BY c.state ORDER BY COUNT(DISTINCT o.customer_id) DESC) AS rank_vehicle_maker
    FROM
        product_t p
    JOIN
        order_t o ON p.product_id = o.product_id
    JOIN
        customer_t c ON o.customer_id = c.customer_id
    GROUP BY
        c.state, p.vehicle_maker
)
-- Select the state, vehicle maker, customer count, and rank of the most preferred vehicle maker in each state
SELECT
    state,
    vehicle_maker,
    customer_count,
    rank_vehicle_maker
FROM
    RankedVehicleMakes
-- Filter to include only the vehicle makers with rank 1 (i.e., the most preferred vehicle maker in each state)
WHERE
    rank_vehicle_maker = 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

-- Select the quarter number and count the number of orders for each quarter
SELECT
    QUARTER_NUMBER,
    COUNT(*) AS num_orders
FROM
    order_t
-- Group the results by quarter number
GROUP BY
    QUARTER_NUMBER
-- Arrange the results in ascending order of quarter number
ORDER BY
    QUARTER_NUMBER;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
      
-- Calculate the total revenue for each quarter
WITH RevenueByQuarter AS (
    SELECT
        QUARTER_NUMBER,
        SUM(VEHICLE_PRICE * QUANTITY * (1 - DISCOUNT)) AS total_revenue
    FROM order_t
    GROUP BY QUARTER_NUMBER
),
-- Calculate the quarter-over-quarter percentage change in revenue
QuarterlyRevenueChange AS (
    SELECT
        QUARTER_NUMBER,
        total_revenue,
        -- Calculate the revenue of the previous quarter using the LAG window function
        LAG(total_revenue) OVER (ORDER BY QUARTER_NUMBER) AS prev_quarter_revenue,
        -- Calculate the quarter-over-quarter percentage change in revenue
        (total_revenue - LAG(total_revenue) OVER (ORDER BY QUARTER_NUMBER)) * 100.0 / NULLIF(LAG(total_revenue) OVER (ORDER BY QUARTER_NUMBER), 0) AS qoq_percentage_change
    FROM RevenueByQuarter
)
-- Select the quarter number, total revenue, and quarter-over-quarter percentage change in revenue
SELECT
    QUARTER_NUMBER,
    total_revenue,
    qoq_percentage_change
FROM QuarterlyRevenueChange;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

-- Select the quarter number, calculate the total revenue, and count the number of orders for each quarter
SELECT
    QUARTER_NUMBER,
    SUM(VEHICLE_PRICE * QUANTITY * (1 - DISCOUNT)) AS total_revenue, -- Calculate total revenue considering vehicle price, quantity, and discount
    COUNT(*) AS num_orders -- Count the number of orders
FROM
    order_t
-- Group the results by quarter number
GROUP BY
    QUARTER_NUMBER
-- Arrange the results in ascending order of quarter number
ORDER BY
    QUARTER_NUMBER;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

-- Select the credit card type from customers and calculate the average discount offered for each credit card type
SELECT
   C.CREDIT_CARD_TYPE,
   AVG(O.DISCOUNT) AS average_discount
FROM
    order_t AS O
-- Join the 'order_t' table with the 'customer_t' table based on the customer IDs
JOIN
    customer_t AS C
ON
    O.CUSTOMER_ID = C.CUSTOMER_ID
-- Group the results by credit card type
GROUP BY
    C.CREDIT_CARD_TYPE;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

-- Select the quarter number and calculate the average number of days taken to ship orders for each quarter
SELECT
    QUARTER_NUMBER,
    AVG(DATEDIFF(SHIP_DATE, ORDER_DATE)) AS avg_days_to_ship
FROM
    order_t
-- Group the results by quarter number
GROUP BY
    QUARTER_NUMBER
-- Arrange the results in ascending order of quarter number
ORDER BY
    QUARTER_NUMBER;

-- ------------------------------------------------------------------------------------------------------

-- Total Revenue 

SELECT SUM(QUANTITY * VEHICLE_PRICE * (1 - DISCOUNT)) AS Total_Revenue
FROM order_t;

-- -------------------------------------------------------------------------------------------------------

-- Total Orders  

SELECT COUNT(*) AS Total_Orders
FROM order_t;

-- -------------------------------------------------------------------------------------------------------

-- Total Customers  

SELECT COUNT(DISTINCT CUSTOMER_ID) AS Total_Customers
FROM customer_t;

-- ---------------------------------------------------------------------------------------------------------

-- Average Ratings 

WITH RatingValues AS (
    SELECT
        CASE CUSTOMER_FEEDBACK
            WHEN 'Very Bad' THEN 1
            WHEN 'Bad' THEN 2
            WHEN 'Okay' THEN 3
            WHEN 'Good' THEN 4
            WHEN 'Very Good' THEN 5
            ELSE NULL
        END AS numeric_rating
    FROM order_t
)
SELECT AVG(numeric_rating) AS Avg_Rating
FROM RatingValues;

-- ---------------------------------------------------------------------------------------------------------

-- Last Quarter Revenue 

SELECT SUM(QUANTITY * VEHICLE_PRICE * (1 - DISCOUNT)) AS Last_Quarter_Revenue
FROM order_t
WHERE QUARTER_NUMBER = (SELECT MAX(QUARTER_NUMBER) FROM order_t);

-- ---------------------------------------------------------------------------------------------------------

-- Last Quarter Orders 

SELECT COUNT(*) AS Last_Quarter_Orders
FROM order_t
WHERE QUARTER_NUMBER = (SELECT MAX(QUARTER_NUMBER) FROM order_t);

-- ---------------------------------------------------------------------------------------------------------

-- Average days to ship 

SELECT AVG(DATEDIFF(SHIP_DATE, ORDER_DATE)) AS Avg_Days_to_Ship
FROM order_t;

-- ---------------------------------------------------------------------------------------------------------

-- Percentage Good Feedback 

SELECT (COUNT(CASE WHEN CUSTOMER_FEEDBACK IN ('Good', 'Very Good') THEN 1 END) * 100.0 / COUNT(*)) AS Percentage_Good_Feedback
FROM order_t;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



