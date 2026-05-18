-- Basic
-- 1. Retrieve the total number of orders placed.
SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;

-- 2. Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(o.quantity * p.price), 2) AS revenue
FROM
    order_details o
        JOIN
    pizzas p ON p.pizza_id = o.pizza_id;

-- 3. Identify the highest-priced pizza.
select * from pizzas
where price = (select max(price) from pizzas);

SELECT 
    t.category,t.name, p.price
FROM
    pizzas p
        JOIN
    pizza_types t ON p.pizza_type_id = t.pizza_type_id
ORDER BY price DESC
limit 1;

-- 4. Identify the most common pizza size ordered.

SELECT 
    p.size, COUNT(p.pizza_id) AS order_count
FROM
    order_details o
        JOIN
    pizzas p ON p.pizza_id = o.pizza_id
GROUP BY p.size
ORDER BY order_count DESC
LIMIT 1;

-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT 
    p.pizza_type_id, t.name, SUM(o.quantity) AS tot_quantity
FROM
    pizzas p
        JOIN
    order_details o ON p.pizza_id = o.pizza_id
        JOIN
    pizza_types t ON t.pizza_type_id = p.pizza_type_id
GROUP BY p.pizza_type_id , t.name
ORDER BY tot_quantity DESC
LIMIT 5;

-- Intermediate :
-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    t.category, SUM(o.quantity) AS tot_order_quantity
FROM
    pizzas p
        JOIN
    order_details o ON p.pizza_id = o.pizza_id
        JOIN
    pizza_types t ON t.pizza_type_id = p.pizza_type_id
GROUP BY t.category
ORDER BY tot_order_quantity DESC;

-- 7. Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) as hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(order_time)
ORDER BY order_count DESC;

-- 8. Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    t.category, COUNT(o.pizza_id) AS pizza_count
FROM
    pizzas p
        JOIN
    order_details o ON p.pizza_id = o.pizza_id
        JOIN
    pizza_types t ON t.pizza_type_id = p.pizza_type_id
GROUP BY t.category;

-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    ROUND(AVG(tot_pizzas), 0) AS avg_pizzas_ordered_per_day
FROM
    (SELECT 
        DATE(o.order_date) AS order_date,
            SUM(d.quantity) AS tot_pizzas
    FROM
        orders o
    JOIN order_details d ON d.order_id = o.order_id
    GROUP BY DATE(o.order_date)) t;

# 10. Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    p.pizza_type_id,
    t.name,
    SUM(p.price * o.quantity) AS revenue
FROM
    order_details o
        JOIN
    pizzas p ON p.pizza_id = o.pizza_id
        JOIN
    pizza_types t ON p.pizza_type_id = t.pizza_type_id
GROUP BY p.pizza_type_id , t.name
ORDER BY revenue DESC
LIMIT 3;

-- Advanced :
-- 11. Calculate the percentage contribution of each pizza type to total revenue.
-- ( each pizza type revenue to total revenue )

with revenue as (
SELECT 
    p.pizza_type_id, SUM(p.price * o.quantity) AS sum_revenue
FROM
    order_details o
        JOIN
    pizzas p ON p.pizza_id = o.pizza_id
GROUP BY p.pizza_type_id)
select pizza_type_id,round((sum_revenue/sum(sum_revenue) over())*100,2) as t_revenue from revenue
order by t_revenue desc;

-- contribution of each pizza category to total revenue.

SELECT pizza_types.category,
    ROUND(
        SUM(order_details.quantity * pizzas.price) /(
            SELECT 
                ROUND(SUM(order_details.quantity * pizzas.price), 2)
            FROM order_details
            JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
        ) * 100,
    2) AS revenue
FROM pizza_types
JOIN pizzas
    ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
    ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;

-- 12. Analyze the cumulative revenue generated over time.

SELECT 
    DATE(order_date), revenue,
    round(SUM(revenue) OVER(
        ORDER BY revenue DESC
    ),2) AS cumulative_revenue
FROM
    (SELECT 
        DATE(o.order_date) AS order_date,
            round(SUM(d.quantity*p.price),1) AS revenue
    FROM
        orders o
    JOIN order_details d ON d.order_id = o.order_id
    join pizzas p on d.pizza_id = p.pizza_id
    GROUP BY DATE(o.order_date)) t;


-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
-- (1. every pizza type revenue grouped by pizza category..... 
-- 2. rank them based on revenue within each category 
-- 3. getting top 3 from each category ... since 4 categories total 12 values)
select * from(
select category,pizza_type_id,revenue, 
RANK() OVER(
    PARTITION BY category
    ORDER BY revenue DESC
) as revenue_rank,avg_price
from(
select t.category,t.pizza_type_id,round(sum(p.price*d.quantity),2) as revenue,
round(avg(p.price),2) as avg_price from pizza_types t
join pizzas p
on t.pizza_type_id = p.pizza_type_id
join order_details d
on d.pizza_id = p.pizza_id
group by t.category,t.pizza_type_id)t
)x
where revenue_rank <= 3;

-- Additional Questions
-- 1. Pizza variants with highest revenue and total orders.

SELECT 
    t.category,
    COUNT(DISTINCT t.pizza_type_id) AS variants,
    ROUND(SUM(p.price * o.quantity), 0) AS revenue,
    SUM(o.quantity) AS t_orders
FROM
    pizza_types t
        JOIN
    pizzas p ON t.pizza_type_id = p.pizza_type_id
        JOIN
    order_details o ON o.pizza_id = p.pizza_id
GROUP BY t.category;

-- 2. Average price of each pizza category.

SELECT 
    t.category, ROUND(AVG(p.price), 2) AS avg_price
FROM
    pizza_types t
        JOIN
    pizzas p ON t.pizza_type_id = p.pizza_type_id
        JOIN
    order_details o ON o.pizza_id = p.pizza_id
GROUP BY t.category
ORDER BY t.category;

-- 3. Pizzas with no sales recorded.

select * from(
select t.category,t.pizza_type_id,p.size,p.price,round(sum(d.quantity*p.price),2) as revenue,
sum(d.quantity) t_quantity,
rank() over(partition by t.category order by round(sum(d.quantity*p.price),2) desc) as revenue_rank from pizzas p
join pizza_types t
on t.pizza_type_id=p.pizza_type_id
left join order_details d
on d.pizza_id = p.pizza_id
group by t.category,t.pizza_type_id,p.size,p.price)t
where revenue is null
order by category;