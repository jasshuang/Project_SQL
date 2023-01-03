## 1. What are the products that below average stock that might need to reorder?

```
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
```

### Results
|Product_Name | Product_ID | Quantity| 
|--- | --- | --- | 
|Ritchey Timberwolf Frameset - 2016|2|5
|Surly Wednesday Frameset - 2016|3|6
|Trek Fuel EX 8 29 - 2016|4|13


## 2.Which orders have a processing time of over 2 days? What’s the customer’s name and email so we can contact them to provide a discount?
```
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

```


### Results
|Order ID | Order Date | Shipped Date|Customer ID |First Name | Last Name | Email| 
|--- | --- | --- | --- | --- | --- | --- | 
|599|2016-12-09|2016-12-12|1|Debra|Burks|debra.burks@yahoo.com
|571|2016-11-24|2016-11-27|5|Charolette|Rice|charolette.rice@msn.com
|1059|2017-08-14|2017-08-17|6|Lyndsey|Bean|lyndsey.bean@hotmail.com

## 3. How many orders are late each year? ( shipped date > required date)
```
with cte as (
	SELECT
		order_id,
		substring(cast(required_date as varchar),1,4) as year
	FROM sales.orders
	WHERE shipped_date > required_date
	)
SELECT
	COUNT(order_id),
	year
FROM CTE
GROUP BY year
```

### Results
|Num_Late_Orders | Year| 
|--- | --- | 
|191|2016|
|215|2017|
|52|2018|

## 4. What is the average order processing time? (days)
```
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
```

### Results

|avg_processing_time|
|---|
|1.98|


## 5. Total sales of each month in 2018.
```
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
```

### Results
|Year | Month| Total_sales| 
|--- | --- | --- | 
|2018	|01	|52|
|2018|02|35|
|2018	|03	|68|


## 6. Which staff make the highest sales? What is his/her first and last name and staff id?
```
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
```

### Results
|staff_id|first_name|last_name|total_sales|
|---|---|---|---|
|6|Marcelene|Boyer|2624120.6530|



## 7. Which store makes the highest sales? What's the store ID and how many staff are there?

```
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

```

### Results

|store_id|	store_name|city|total_sales|
|---|	---|---|---|
|2|Baldwin Bikes|Baldwin|5215751.2775|

## 8. For the best selling item. Which staff sold the most
```
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
GROUP BY sales.orders.staff_id, sales.staffs.first_name, sales.staffs.last_name, best_seller.product_name
ORDER BY count(sales.order_items.order_id) desc;

```

### Results

|number_of_sales|staff_id|first_name|last_name|product_name|
|---|---|---|---|---|
|37|6|Marcelene|Boyer|SurlyIce Cream Truck Frameset - 2016|

## 9. Which item is the most reordered

```
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
```
### Results

|product_id|total_orders|num_customer|
|---|---|---|
|3|4|2|
|20|4|2|
