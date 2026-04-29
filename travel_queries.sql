create database travel_db;
use travel_db;


CREATE TABLE departures (
    year                  INT,
    departures_millions   DECIMAL(5,2),
    yoy_growth_pct        DECIMAL(6,1),
    avg_trip_days         DECIMAL(4,1),
    avg_spend_usd         INT,
    business_pct          DECIMAL(4,1),
    leisure_pct           DECIMAL(4,1),
    vfr_pct               DECIMAL(4,1)
);
select * from departures;
SELECT
    year,
    departures_millions,
    LAG(departures_millions) OVER (ORDER BY year) AS prev_year_millions,
    ROUND(
        (departures_millions - LAG(departures_millions) OVER (ORDER BY year))
        / LAG(departures_millions) OVER (ORDER BY year) * 100
    , 1) AS yoy_growth_calculated,
    avg_spend_usd,
    departures_millions * avg_spend_usd AS total_spend_usd_millions
FROM departures
ORDER BY year;

CREATE TABLE destinations (
    rank_num              INT,
    destination           VARCHAR(50),
    travelers_millions    DECIMAL(5,2),
    yoy_growth_pct        DECIMAL(5,1),
    avg_stay_days         INT,
    avg_spend_usd         INT,
    top_season            VARCHAR(20),
    visa_type             VARCHAR(30)
);
select * from destinations;
SELECT
    RANK() OVER (ORDER BY travelers_millions DESC) AS rank_num,
    destination,
    travelers_millions,
    yoy_growth_pct,
    avg_stay_days,
    avg_spend_usd,
    visa_type,
    top_season
FROM destinations
ORDER BY travelers_millions DESC;
SELECT
    visa_type,
    COUNT(*) AS num_destinations,
    SUM(travelers_millions) AS total_travelers_millions,
    ROUND(AVG(avg_spend_usd), 0) AS avg_spend_per_trip,
    ROUND(AVG(avg_stay_days), 1) AS avg_stay_days
FROM destinations
GROUP BY visa_type
ORDER BY total_travelers_millions DESC;
SELECT
    destination,
    travelers_millions,
    avg_spend_usd,
    avg_stay_days,
    avg_spend_usd * avg_stay_days AS value_score,
    RANK() OVER (ORDER BY avg_spend_usd * avg_stay_days DESC) AS value_rank,
    RANK() OVER (ORDER BY travelers_millions DESC) AS volume_rank,
    yoy_growth_pct,
    visa_type
FROM destinations
ORDER BY value_score DESC;

CREATE TABLE corridors (
    corridor              VARCHAR(60),
    monthly_travelers     INT,
    avg_fare_inr          INT,
    avg_stay_days         INT,
    leisure_pct           DECIMAL(5,1),
    business_pct          DECIMAL(5,1),
    vfr_pct               DECIMAL(5,1),
    cagr_pct              DECIMAL(5,1)
);
select * from corridors;
SELECT
    corridor,
    monthly_travelers,
    monthly_travelers * 12 AS annual_travelers,
    avg_fare_inr,
    ROUND(monthly_travelers * 12 * avg_fare_inr / 10000000.0, 2) AS est_revenue_cr,
    cagr_pct,
    leisure_pct,
    business_pct
FROM corridors
ORDER BY est_revenue_cr DESC;
SELECT
    corridor,
    leisure_pct,
    business_pct,
    vfr_pct,
    monthly_travelers,
    avg_fare_inr,
    CASE
        WHEN business_pct >= 40 THEN 'Primarily Business'
        WHEN leisure_pct >= 70 THEN 'Primarily Leisure'
        WHEN vfr_pct >= 30 THEN 'Primarily VFR'
        ELSE 'Mixed Purpose'
    END AS route_type
FROM corridors
ORDER BY monthly_travelers DESC;
SELECT
    RANK() OVER (ORDER BY cagr_pct DESC) AS growth_rank,
    corridor,
    cagr_pct,
    monthly_travelers,
    avg_fare_inr,
    leisure_pct,
    business_pct,
    ROUND(monthly_travelers * avg_fare_inr * 12 / 10000000.0, 1) AS rev_cr
FROM corridors
ORDER BY cagr_pct DESC;

CREATE TABLE agents (
    agent_id              VARCHAR(10),
    agent_name            VARCHAR(50),
    city                  VARCHAR(30),
    total_bookings        INT,
    revenue_lakh          DECIMAL(6,1),
    avg_markup_pct        DECIMAL(5,1),
    conversion_rate_pct   DECIMAL(5,1),
    repeat_client_pct     DECIMAL(5,1),
    agent_tier            VARCHAR(15)
);
select * from agents;
SELECT
    agent_tier,
    COUNT(*) AS num_agents,
    SUM(total_bookings) AS total_bookings,
    ROUND(SUM(revenue_lakh), 1) AS total_revenue_lakh,
    ROUND(AVG(revenue_lakh), 1) AS avg_revenue_per_agent,
    ROUND(AVG(avg_markup_pct), 1) AS avg_markup_pct,
    ROUND(AVG(conversion_rate_pct), 1) AS avg_conversion_pct,
    ROUND(AVG(repeat_client_pct), 1) AS avg_repeat_pct
FROM agents
GROUP BY agent_tier
ORDER BY total_revenue_lakh DESC;
SELECT
    agent_name,
    city,
    agent_tier,
    total_bookings,
    revenue_lakh,
    conversion_rate_pct,
    repeat_client_pct,
    RANK() OVER (ORDER BY revenue_lakh DESC) AS overall_rank,
    RANK() OVER (
        PARTITION BY city
        ORDER BY revenue_lakh DESC
    ) AS rank_in_city
FROM agents
ORDER BY overall_rank;
SELECT
    agent_name,
    city,
    agent_tier,
    revenue_lakh,
    conversion_rate_pct,
    repeat_client_pct,
    CASE
        WHEN revenue_lakh >= 70 THEN 'Star Performer'
        WHEN revenue_lakh >= 45 THEN 'High Performer'
        WHEN revenue_lakh >= 25 THEN 'Solid Performer'
        ELSE 'Needs Development'
    END AS performance_band,
    CASE
        WHEN conversion_rate_pct >= 60 THEN 'High Converter'
        WHEN conversion_rate_pct >= 50 THEN 'Good Converter'
        ELSE 'Low Converter'
    END AS conversion_band
FROM agents
ORDER BY revenue_lakh DESC;


CREATE TABLE packages (
    package_type          VARCHAR(30),
    total_bookings        INT,
    revenue_cr            DECIMAL(6,2),
    avg_value_inr         INT,
    avg_margin_pct        DECIMAL(5,1),
    top_destination       VARCHAR(40),
    avg_group_size        DECIMAL(4,1),
    cancellation_pct      DECIMAL(5,1),
    yoy_growth_pct        DECIMAL(5,1)
);
select * from packages;
SELECT
    package_type,
    total_bookings,
    revenue_cr,
    avg_margin_pct,
    avg_value_inr,
    cancellation_pct,
    yoy_growth_pct,
    RANK() OVER (ORDER BY avg_margin_pct DESC) AS margin_rank,
    RANK() OVER (ORDER BY revenue_cr DESC) AS revenue_rank,
    RANK() OVER (ORDER BY yoy_growth_pct DESC) AS growth_rank
FROM packages
ORDER BY margin_rank;


CREATE TABLE monthly_funnel (
    month_name            VARCHAR(20),
    month_num             INT,
    inquiries             INT,
    quotes_sent           INT,
    bookings_confirmed    INT,
    quote_to_booking_pct  DECIMAL(5,1),
    avg_booking_value_inr INT,
    cancellations         INT,
    net_revenue_lakh      DECIMAL(7,1),
    mom_growth_pct        DECIMAL(6,1)
);
select * from monthly_funnel;
SELECT
    month_name,
    month_num,
    inquiries,
    quotes_sent,
    bookings_confirmed,
    cancellations,
    net_revenue_lakh,
    ROUND(quotes_sent * 100.0 / inquiries, 1) AS quote_rate_pct,
    ROUND(bookings_confirmed * 100.0 / quotes_sent, 1) AS book_rate_pct,
    ROUND(bookings_confirmed * 100.0 / inquiries, 1) AS overall_conv_pct,
    ROUND(
        net_revenue_lakh - LAG(net_revenue_lakh) OVER (ORDER BY month_num)
    , 1) AS mom_change_lakh,
    SUM(net_revenue_lakh) OVER (ORDER BY month_num) AS cumulative_revenue
FROM monthly_funnel
ORDER BY month_num;