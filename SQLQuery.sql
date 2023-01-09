-- 1. What are the products that below average stock that might need to reorder?

SELECT
	production.products.product_name,
	production.products.product_id,
	SUM(production.stocks.quantity) AS total_quantity
FROM production.products 
	JOIN production.stocks  ON production.products.product_id = production.stocks.product_ID
WHERE  production.stocks.quantity <
	(SELECT avg(quantity) as avg_quantity
	FROM production.stocks)
GROUP BY production.products.product_name, production.products.product_id



--2. Which orders have a processing time of over 2 days? What’s the customer’s name and email so that we can contact them to provide a discount?

SELECT
	sales.orders.order_id,
	sales.orders.order_date,
	sales.orders.shipped_date,
	sales.orders.customer_id,
	sales.customers.first_name,
	sales.customers.last_name,
	sales.customers.email
FROM sales.orders
	JOIN sales.customers ON sales.orders.customer_id = sales.customers.customer_id
GROUP BY
	sales.orders.order_id,
	sales.orders.shipped_date,
	sales.orders.order_date,
	sales.orders.customer_id,
	sales.customers.first_name,
	sales.customers.last_name,
	sales.customers.email
HAVING
	cast(shipped_date as datetime) - cast(order_date as datetime) > 2
	



--3. How many orders are late in each year? ( shipped date > required date)
with cte as (
	SELECT
		order_id,
		substring(cast(required_date as varchar),1,4) as year
	FROM sales.orders
	WHERE shipped_date > required_date
	)
SELECT
	COUNT(order_id) as num_late_orders,
	year
FROM CTE
GROUP BY year

--4. What is the average order processing time? (days)		

with CTE as (
	SELECT
		cast(shipped_date as datetime) - cast(order_date as datetime) as avg_processing_time
	FROM sales.orders
	),
avg_days as (
	SELECT
		CAST(avg_processing_time AS real) as avg_processing_time
	FROM CTE
	)
SELECT
	round(AVG(avg_processing_time), 2)as avg_processing_time
FROM avg_days




--5. Total of the amount of the order of each month in 2018.

with orders_2018 as (
	SELECT
		substring(cast(order_date as varchar), 1,4) as year,
		substring(substring(cast(order_date as varchar), 6,8),1,2) as month,
		order_id
	FROM sales.orders
	WHERE substring(cast(order_date as varchar), 1,4) = 2018
	)
SELECT
	year,
	month,
	count(order_id) as num_orders
FROM orders_2018
GROUP BY year, Month
ORDER BY month

		
--6. Which staff make the highest sales? What is his/her first and last name and staff id?


WITH sales_total as (
	SELECT
		order_id,
		sum(quantity * list_price * (1-discount)) as total_sales
	FROM sales.order_items
	GROUP BY order_id
	),
staff_total as (
	SELECT top 1
		sum(sales_total.total_sales) as total_sales,
		sales.orders.staff_id
	FROM sales_total JOIN sales.orders ON sales_total.order_id = sales.orders.order_id
	GROUP BY staff_id
	ORDER BY sum(sales_total.total_sales) desc
	)
SELECT 
	sales.staffs.staff_id,
	sales.staffs.first_name,
	sales.staffs.last_name,
	staff_total.total_sales
FROM sales.staffs JOIN staff_total on sales.staffs.staff_id = staff_total.staff_id


--7. Which store makes the highest sales? What's the store ID and how many staff are there?

WITH sales_total as (
	SELECT
		order_id,
		sum(quantity * list_price * (1-discount)) as total_sales
	FROM sales.order_items
	GROUP BY order_id
	),
store_total as (
	SELECT top 1
		sum(sales_total.total_sales) as total_sales,
		sales.orders.store_id
	FROM sales_total JOIN sales.orders ON sales_total.order_id = sales.orders.order_id
	GROUP BY sales.orders.store_id
	ORDER BY sum(sales_total.total_sales) desc
	)
SELECT 
	sales.stores.store_id,
	sales.stores.store_name,
	sales.stores.city,
	store_total.total_sales
FROM sales.stores JOIN store_total on sales.stores.store_id = store_total.store_id





--8. For the best selling item. Which staff sold the most
with best_seller as (
	SELECT top 1 with ties
		sales.order_items.product_id,
		count(sales.order_items.product_id) as amount_sold,
		production.products.product_name
	FROM sales.order_items
	JOIN production.products ON sales.order_items.product_id = production.products.product_id
	GROUP BY production.products.product_name, sales.order_items.product_id
	ORDER BY count(sales.order_items.product_id) desc
)

SELECT top 1 with ties
	count(sales.order_items.order_id) as number_of_sales,
	sales.orders.staff_id,
	sales.staffs.first_name,
	sales.staffs.last_name,
	best_seller.product_name
FROM sales.order_items
	JOIN sales.orders ON order_items.order_id = sales.orders.order_id
	JOIN sales.staffs ON sales.orders.staff_id = sales.staffs.staff_id
	JOIN best_seller on best_seller.product_id = sales.order_items.product_id
-- WHERE sales.order_items.product_id = 6
GROUP BY sales.orders.staff_id, sales.staffs.first_name, sales.staffs.last_name, best_seller.product_name
ORDER BY count(sales.order_items.order_id) desc;



-- 9. Which item is the most reordered
WITH repeat_customers as (
	SELECT
		customer_id,
		order_id,
		COUNT(order_id) over (partition by customer_id) as times_ordered
	FROM sales.orders
	order by times_ordered desc
),
repeat_orders as (
	SELECT
		sales.orders.order_id,
		sales.orders.customer_id
	FROM sales.orders
		inner join repeat_customers on repeat_customers.customer_id = sales.orders.customer_id)
SELECT TOP 1 WITH TIES
	sales.order_items.product_id,
	sales.order_items.order_id,
	count(product_id) OVER(PARTITION BY sales.order_items.order_id, sales.order_items.product_id) as time_purchased 
FROM sales.order_items
	INNER JOIN repeat_orders on sales.order_items.order_id = repeat_orders.order_id
-- GROUP BY sales.order_items.product_id, sales.order_items.order_id
ORDER BY count(product_id) OVER(PARTITION BY sales.order_items.order_id, sales.order_items.product_id);


with base as (
	select
		customer_id,
		product_id,
		count(distinct sales.orders.order_id) as num_order
	from sales.orders
		inner join sales.order_items on sales.order_items.order_id = sales.orders.order_id
	group by customer_id, product_id
), reorders as (
	select 
		product_id,
		sum(num_order) as total_orders,
		count(distinct customer_id) as num_customer
	from base
	where num_order > 1
	group by product_id
)
select *
from reorders
order by total_orders desc;

select *
from sales.order_items;

)

