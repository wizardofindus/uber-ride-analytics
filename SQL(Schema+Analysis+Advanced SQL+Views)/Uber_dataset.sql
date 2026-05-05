create database Uber_trip_database;
use Uber_trip_database;


CREATE TABLE uber_trips (
    trip_id BIGINT primary key,
    driver_id int,
    rider_id int,
    city varchar(50),
    pickup_lat FLOAT,
    pickup_lng FLOAT,
    drop_lat FLOAT,
    drop_lng FLOAT,
    distance_km FLOAT,
    fare_amount FLOAT,
    status_ varchar(50),
    payment_method varchar(50),
    pickup_time datetime,
    drop_time datetime,
    hour_ int,
    day_ int,
    month_ int,
    day_of_week varchar(50),
    time_category varchar(50),
    fare_per_km FLOAT,
    peak_hour int,
    trip_type varchar(50),
    high_fare int,
    demand_index FLOAT
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/USER/Documents/uber_cleaned.csv'
INTO TABLE uber_trips
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from uber_trips;

select count(*) from uber_trips;

# Remove Invalid Coordinates:

DELETE FROM uber_trips
WHERE pickup_lat NOT BETWEEN -90 AND 90
   OR pickup_lng NOT BETWEEN -180 AND 180
   OR drop_lat NOT BETWEEN -90 AND 90
   OR drop_lng NOT BETWEEN -180 AND 180;
   
# Remove Invalid Fares:

DELETE FROM uber_trips
WHERE fare_amount <= 0 OR fare_amount > 500;

# Remove Negative Duration Trips:

DELETE FROM uber_trips
WHERE drop_time < pickup_time;

# Feature Engineering:

# Extract Time Features:

SELECT *,
       HOUR(pickup_time) AS hour,
       DAYNAME(pickup_time) AS day_name,
       MONTH(pickup_time) AS month,
       YEAR(pickup_time) AS year
FROM uber_trips;

# Time Category:

SELECT *,
CASE 
    WHEN HOUR(pickup_time) BETWEEN 5 AND 11 THEN 'Morning'
    WHEN HOUR(pickup_time) BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN HOUR(pickup_time) BETWEEN 17 AND 20 THEN 'Evening'
    ELSE 'Night'
END AS time_category
FROM uber_trips;

# Peak Hour Flag:

SELECT *,
CASE 
    WHEN HOUR(pickup_time) IN (8,9,17,18,19) THEN 1
    ELSE 0
END AS peak_hour
FROM uber_trips;

# Total Revenue:

SELECT sum(fare_amount) AS total_revenue
FROM uber_trips;

# Total Trips:

SELECT COUNT(*) AS total_trips
FROM uber_trips;

# Average Fare:

SELECT round(AVG(fare_amount),2) AS avg_fare
FROM uber_trips;

# Average Distance:

SELECT round(AVG(distance_km),2) AS avg_distance
FROM uber_trips;

# Time-Based Analysis:

# Trips by Hour (Peak Demand):

SELECT 
    HOUR(pickup_time) AS hour,
    COUNT(*) AS total_trips
FROM uber_trips
GROUP BY hour
ORDER BY total_trips DESC;

# Trips by Day of Week:

SELECT 
    DAYNAME(pickup_time) AS day,
    COUNT(*) AS total_trips
FROM uber_trips
GROUP BY day
ORDER BY total_trips DESC;

# Monthly Trends:

SELECT 
    DATE_FORMAT(pickup_time, '%Y-%m') AS month,
    COUNT(*) AS trips,
    SUM(fare_amount) AS revenue
FROM uber_trips
GROUP BY month
ORDER BY month;


# Fare & Distance Analysis:

# Fare vs Distance:

SELECT 
    distance_km,
    round(AVG(fare_amount),2) AS avg_fare
FROM uber_trips
GROUP BY distance_km
ORDER BY distance_km;

# Fare per KM:

SELECT 
    round(AVG(fare_amount / distance_km),2) AS avg_fare_per_km
FROM uber_trips
WHERE distance_km > 0;

# High Fare Trips:

SELECT *
FROM uber_trips
WHERE fare_amount > (
    SELECT AVG(fare_amount) * 2 FROM uber_trips
);

# Location Analysis:

# Top Pickup Locations (Approx by Grid):

SELECT 
    ROUND(pickup_lat,2) AS lat,
    ROUND(pickup_lng,2) AS lon,
    COUNT(*) AS trip_count
FROM uber_trips
GROUP BY lat, lon
ORDER BY trip_count DESC
LIMIT 10;

# Top Dropoff Locations:

SELECT 
    ROUND(drop_lat,2) AS lat,
    ROUND(drop_lng,2) AS lon,
    COUNT(*) AS trip_count
FROM uber_trips
GROUP BY lat, lon
ORDER BY trip_count DESC
LIMIT 10;

# Advanced SQL (Window Functions):

# Rank Most Expensive Trips:

SELECT 
    trip_id,
    fare_amount,
    RANK() OVER (ORDER BY fare_amount DESC) AS fare_rank
FROM uber_trips;

# Top 5 Trips per Month:

SELECT *
FROM (
    SELECT 
        trip_id,
        fare_amount,
        DATE_FORMAT(pickup_time, '%Y-%m') AS month,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_FORMAT(pickup_time, '%Y-%m')
            ORDER BY fare_amount DESC
        ) AS rn
    FROM uber_trips
) t
WHERE rn <= 5;


# Running Revenue:

SELECT 
    pickup_time,
    round(SUM(fare_amount) OVER (
        ORDER BY pickup_time
    ),2) AS cumulative_revenue
FROM uber_trips;

# Moving Average Fare:

SELECT 
    pickup_time,
    round(AVG(fare_amount) OVER (
        ORDER BY pickup_time
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),2) AS moving_avg_fare
FROM uber_trips;

# Business Insight Queries:

# Peak vs Non-Peak Revenue:

SELECT 
    CASE 
        WHEN HOUR(pickup_time) IN (8,9,17,18,19) THEN 'Peak'
        ELSE 'Non-Peak'
    END AS time_type,
    round(SUM(fare_amount),2) AS revenue
FROM uber_trips
GROUP BY time_type;



# Create Views:

# KPI View:

CREATE VIEW uber_kpi AS
SELECT 
    COUNT(*) AS total_trips,
    SUM(fare_amount) AS total_revenue,
    AVG(fare_amount) AS avg_fare,
    AVG(distance_km) AS avg_distance
FROM uber_trips;


# Monthly Trend:


CREATE VIEW uber_monthly_trend AS
SELECT 
    DATE_FORMAT(pickup_time, '%Y-%m') AS month,
    COUNT(*) AS trips,
    SUM(fare_amount) AS revenue
FROM uber_trips
GROUP BY month;


# Hourly Demand:

CREATE VIEW uber_hourly_demand AS
SELECT 
    HOUR(pickup_time) AS hour,
    COUNT(*) AS trips
FROM uber_trips
GROUP BY hour;


# Location Data (for map):

CREATE VIEW uber_location AS
SELECT 
    pickup_lat,
    pickup_lng,
    COUNT(*) AS trips
FROM uber_trips
GROUP BY pickup_lat, pickup_lng;



