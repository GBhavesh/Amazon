-- Analysis 1
--q1 To simplify its financial reports, Amazon India needs to standardize payment values. 
--Round the average payment values to integer (no decimal)
--for each payment type and display the results sorted in ascending order.

SELECT 
    payment_type, 
    CAST(ROUND(AVG(payment_value)::numeric, 0) AS INTEGER) AS rounded_avg_payment
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment;

--q2 To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type. 
--Calculate the percentage of total orders for each payment type, rounded to one decimal place, 
--and display them in descending order
SELECT 
    payment_type,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM amazon_brazil.payments), 1) AS percentage_orders
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY percentage_orders DESC;

--q3 Amazon India seeks to create targeted promotions for products within specific price ranges.
--Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. 
--Display these products, sorted by price in descending order.

SELECT P.product_id ,O.price , P.product_category_name FROM amazon_brazil.product as P
join amazon_brazil.order_items as O
on P.product_id=O.product_id
where O.price between 100 and 500 and P.product_category_name Ilike'%Smart%'
order by O.price desc




--q4 To identify seasonal sales patterns, Amazon India needs to focus on the most successful months. 
--Determine the top 3 months with the highest total sales value, rounded to the nearest integer.
--Output: month, total_sales
SELECT 
    EXTRACT(MONTH FROM O.order_purchase_timestamp) AS month,
    ROUND(SUM(I.price)) AS total_sales
FROM amazon_brazil.orders AS O
JOIN amazon_brazil.order_items AS I
  ON O.order_id = I.order_id
GROUP BY month
ORDER BY total_sales DESC
LIMIT 3;

--q5Amazon India is interested in product categories with significant price variations. 
--Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.
--Output: product_category_name, price_difference
SELECT  P.product_category_name,(max(O.price)-min(O.price)) as  price_difference 
FROM amazon_brazil.product as P
join amazon_brazil.order_items as O
on P.product_id=O.product_id
group by P.product_category_name 

--q7Amazon India wants to identify products that may have incomplete name in order to fix it from their end.
--Retrieve the list of products where the product category name is missing or contains only a single character.
--Output: product_id, product_category_name
select product_id,product_category_name from amazon_brazil.product
where product_category_name is NULL or length(product_category_name)=1


--q6 To enhance the customer experience, 
--Amazon India wants to find which payment types have the most consistent transaction amounts.
--Identify the payment types with the least variance in transaction amounts, 
--sorting by the smallest standard deviation first.
--Output: payment_type, std_deviation
SELECT 
    payment_type,
    ROUND(VARIANCE(payment_value)::numeric, 2) AS variance,
    ROUND(STDDEV(payment_value)::numeric, 2) AS std_deviation
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY variance ASC

------------------------------------------------------------------------------------------------------------------------
-- Analysis 2
--Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. 
--Calculate the count of each payment type within these ranges and display the results in descending order of count
--Output: order_value_segment, payment_type, count
select payment_type,count(payment_type)as count,
case 
when payment_value>=1000 then'High'
when payment_value between 200 and 1000 then 'Medium'
else 'Low'
end as  order_value_segment
from  amazon_brazil.payments
group by payment_type,order_value_segment
order by count desc


--Amazon India wants to analyse the price range and average price for each product category. 
--Calculate the minimum, maximum, and average price for each category, 
--and list them in descending order by the average price.
--Output: product_category_name, min_price, max_price, avg_price

select product_category_name,max(price) as  max_price ,min(price) as min_price ,
avg(price) as avg_price
from amazon_brazil.product  as P
join amazon_brazil.order_items as U on
P.product_id =U.product_id
group by product_category_name
order by avg_price desc



--Amazon India wants to identify the customers who have placed multiple orders over time. 
--Find all customers with more than one order, 
--and display their customer unique IDs along with the total number of orders they have placed.
--Output: customer_unique_id, total_orders
select customer_unique_id,count(order_id) as total_orders
from amazon_brazil.orders O
join  amazon_brazil.customer C
on O.customer_id=C.customer_id
group by customer_unique_id
having count(order_id)>1
order by total_orders desc



--Amazon India wants to categorize customers into different types 
--('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) 
--based on their purchase history.
--Use a temporary table to define these categories
--and join it with the customers table to update and display the customer types.
--Output: customer_unique_id, customer_type

With my_cte as(
Select customer_unique_id,count(*),
case 
when count(*)=1 then 'New'
when count(*) between 2 and 4 then 'Returning'
else 'Loyal'
end as customer_type from amazon_brazil.orders O
join amazon_brazil.customer C on O.customer_id=C.customer_id
group by customer_unique_id)
select M.customer_unique_id,M.customer_type from my_cte M
join amazon_brazil.customer C
on M.customer_unique_id=C.customer_unique_id
order by M.customer_type


--Amazon India wants to know which product categories generate the most revenue. 
--Use joins between the tables to calculate the total revenue for each product category. 
--Display the top 5 categories.
--Output: product_category_name, total_revenue

select product_category_name ,Sum((O.price-O.freight_value)) as total_revenue
from amazon_brazil.product P
join amazon_brazil.order_items O
on P.product_id=O.product_id
group by product_category_name
order by total_revenue desc
limit 5
------------------------------------------------------------------------------------------------------------------------------------
-- Analysis-3
 --Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter)
-- based on order purchase dates, and display the results. 
-- Spring is in the months of March, April and May.
--Summer is from June to August and Autumn is between September and November
--and rest months are Winter. 
--Output: season, total_sales
select season,total_sales from(
select
case
when extract(month from order_purchase_timestamp) in(3,4,5) then 'Spring'
when extract(month from order_purchase_timestamp) in(6,7,8) then 'Summer'
when extract(month from order_purchase_timestamp) in(9,10,11) then 'Autumn'
else 'Winter'
end as season,sum(OI.price-OI.freight_value) as total_sales
from  amazon_brazil.orders  as O join
 amazon_brazil.order_items as OI on
 O.order_id=OI.order_id
group by season) as st












--The inventory team is interested in identifying products that have sales volumes above the overall average. 
--Write a query that uses a subquery to filter products with a total quantity sold above the average quantity.
--Output: product_id, total_quantity_sold
SELECT product_id, total_quantity_sold
FROM (
    SELECT 
        P.product_id,
        COUNT(O.order_item_id) AS total_quantity_sold
    FROM amazon_brazil.order_items O
    JOIN amazon_brazil.product P
        ON O.product_id = P.product_id
    GROUP BY P.product_id
) AS product_totals
WHERE total_quantity_sold > (
    SELECT AVG(count_per_product) 
    FROM (
        SELECT COUNT(OI.order_item_id) AS count_per_product
        FROM amazon_brazil.order_items OI
        GROUP BY OI.product_id
    ) AS avg_subquery
)
ORDER BY total_quantity_sold;









--A loyalty program is being designed  for Amazon India. 
--Create a segmentation based on purchase frequency: ‘Occasional’ for customers with 1-2 orders, 
--‘Regular’ for 3-5 orders, 
--and ‘Loyal’ for more than 5 orders. 
--Use a CTE to classify customers and their count .--Output: customer_type, count
with customer_orders as (
select count(*) as order_count ,  O.customer_id
from amazon_brazil.orders O
join amazon_brazil.customer C
on O.customer_id =C.customer_id
group by  O.customer_id)
select
case
when order_count between 1 and 2 then 'Occasional'
when order_count between 3 and 5 then 'Regular'
else 'Loyal'
end as customer_type,count(*) as customer_count
from customer_orders
group by customer_type
order by  customer_count

-- Amazon wants to identify high-value customers to target for an exclusive rewards program. 
--You are required to rank customers based on their average order value (avg_order_value) 
--to find the top 20 customers.
--Output: customer_id, avg_order_value, and customer_rank

WITH customer_avg AS (
    SELECT 
        O.customer_id,
        AVG(OI.price - OI.freight_value) AS avg_order_value
    FROM amazon_brazil.orders O
    JOIN amazon_brazil.order_items OI
        ON O.order_id = OI.order_id
    GROUP BY O.customer_id
)
SELECT 
    customer_id,
    avg_order_value,
    DENSE_RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM customer_avg
ORDER BY customer_rank
LIMIT 20;


--To understand how different payment methods affect monthly sales growth,
--Amazon wants to compute the total sales for each payment method and 
--calculate the month-over-month growth rate for the past year (year 2018). 
--Write query to first calculate total monthly sales for each payment method, 
--then compute the percentage change from the previous month.
--Output: payment_type, sale_month, monthly_total, monthly_change.


With monthly_sales as(
 select payment_type,sum(O.price-O.freight_value) as monthly_total,
 TO_CHAR(OI.order_purchase_timestamp,'YYYY-MM') AS sale_month
 from amazon_brazil.payments P
 join amazon_brazil.order_items O
 on P.order_id =O.order_id
 join amazon_brazil.orders OI
 on O.order_id=OI.order_id
 WHERE extract(year from OI.order_purchase_timestamp)=2018
 group by  payment_type,sale_month)
SELECT 
    payment_type,
    sale_month,
    monthly_total,
    ROUND(
        (
            (monthly_total - LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month)) 
            / NULLIF(LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month), 0)
        )::NUMERIC, 2
    ) AS monthly_change
FROM monthly_sales
ORDER BY payment_type, sale_month;



--Amazon wants to analyze sales growth trends for its key products over their lifecycle.
--Calculate monthly cumulative sales for each product from the date of its first sale.
--Output: product_id, sale_month, and total_sales

SELECT 
    oi.product_id,
    TO_CHAR(DATE_TRUNC('month', o.order_purchase_timestamp), 'YYYY-MM') AS sale_month,
    SUM(oi.price - oi.freight_value) AS monthly_sales,
    SUM(SUM(oi.price - oi.freight_value)) 
        OVER (PARTITION BY oi.product_id ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp)) AS total_sales
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.orders o 
    ON oi.order_id = o.order_id
GROUP BY oi.product_id, DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY oi.product_id, sale_month;


--To understand seasonal sales patterns, 
--the finance team is analysing the monthly revenue trends over the past year (year 2018).
--Run a query to calculate total revenue generated each month and identify periods of peak and low sales. 
 --Output: month, total_revenue
SELECT 
    TO_CHAR(DATE_TRUNC('month', order_purchase_timestamp), 'YYYY-MM') AS month,
    SUM(price - freight_value) AS total_revenue
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.orders o
    ON oi.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;















































