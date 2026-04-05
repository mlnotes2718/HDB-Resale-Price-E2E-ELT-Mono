{{ config(
    materialized='table',
    tags=['fact'],
    partition_by={
        "field": "transaction_date",
        "data_type": "date",
        "granularity": "month"
    }
) }}

WITH fact_data AS (
    SELECT
        stg.transaction_key,
        
        -- Dimension keys
        dd.date_key,
        dl.location_key,
        dp.property_key,
        
        -- Degenerate dimensions (low cardinality attributes kept in fact table)
        stg.block,
        
        -- Measures
        stg.floor_area_sqm,
        stg.resale_price,
        stg.lease_commence_date,
        stg.remaining_lease_years,
        stg.remaining_lease_months,
        stg.total_remaining_lease_months,
        
        -- Calculated measures
        stg.resale_price / stg.floor_area_sqm AS price_per_sqm,
        stg.transaction_year - stg.lease_commence_date AS property_age_years,
        stg.total_remaining_lease_months / 12.0 AS remaining_lease_years_decimal,
        
        -- Date fields for partitioning and analysis
        stg.transaction_date,
        stg.transaction_year,
        stg.transaction_month,
        
        -- Audit fields
        stg.loaded_at
        
    FROM {{ ref('stg_resale_transactions') }} stg
    LEFT JOIN {{ ref('dim_date') }} dd 
        ON stg.transaction_date = dd.date_value
    LEFT JOIN {{ ref('dim_location') }} dl 
        ON {{ dbt_utils.generate_surrogate_key(['stg.town', 'stg.street_name']) }} = dl.location_key
    LEFT JOIN {{ ref('dim_property') }} dp 
        ON {{ dbt_utils.generate_surrogate_key(['stg.flat_type', 'stg.flat_model', 'stg.storey_range']) }} = dp.property_key
)

SELECT * FROM fact_data