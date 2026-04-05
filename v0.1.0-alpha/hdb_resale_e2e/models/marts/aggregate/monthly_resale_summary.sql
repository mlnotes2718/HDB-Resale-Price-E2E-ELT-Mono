{{ config(
    materialized='table',
    tags=['aggregate']
) }}

SELECT
    dd.year_month,
    dd.year,
    dd.month,
    dl.town,
    dl.region,
    dp.flat_type,
    dp.flat_size_category,
    
    -- Aggregated metrics
    COUNT(*) AS transaction_count,
    AVG(f.resale_price) AS avg_resale_price,
    
    -- Use APPROX_QUANTILES for median calculation in BigQuery
    APPROX_QUANTILES(f.resale_price, 2)[OFFSET(1)] AS median_resale_price,
    
    MIN(f.resale_price) AS min_resale_price,
    MAX(f.resale_price) AS max_resale_price,
    STDDEV(f.resale_price) AS stddev_resale_price,
    
    -- Additional percentiles
    APPROX_QUANTILES(f.resale_price, 4)[OFFSET(1)] AS p25_resale_price,
    APPROX_QUANTILES(f.resale_price, 4)[OFFSET(3)] AS p75_resale_price,
    
    AVG(f.price_per_sqm) AS avg_price_per_sqm,
    APPROX_QUANTILES(f.price_per_sqm, 2)[OFFSET(1)] AS median_price_per_sqm,
    
    AVG(f.floor_area_sqm) AS avg_floor_area_sqm,
    AVG(f.property_age_years) AS avg_property_age_years,
    AVG(f.remaining_lease_years_decimal) AS avg_remaining_lease_years
    
FROM {{ ref('fact_resale_transactions') }} f
LEFT JOIN {{ ref('dim_date') }} dd ON f.date_key = dd.date_key
LEFT JOIN {{ ref('dim_location') }} dl ON f.location_key = dl.location_key  
LEFT JOIN {{ ref('dim_property') }} dp ON f.property_key = dp.property_key

GROUP BY 1,2,3,4,5,6,7