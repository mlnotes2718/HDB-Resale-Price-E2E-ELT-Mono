{{ config(
    materialized='view',
    tags=['staging']
) }}

WITH source_data AS (
    SELECT *
    FROM {{ source('hdb_resale_raw', 'clean_hdb_resale_file') }}
),

cleaned_data AS (
    SELECT
        -- Create surrogate key using ALL available fields to ensure uniqueness
        {{ dbt_utils.generate_surrogate_key(['month', 'town', 'street_name', 'block', 'flat_type', 'storey_range', 'floor_area_sqm', 'flat_model', 'lease_commence_date', 'remaining_lease', 'resale_price']) }} AS transaction_key,
        
        -- Parse and clean date
        PARSE_DATE('%Y-%m', month) AS transaction_date,
        EXTRACT(YEAR FROM PARSE_DATE('%Y-%m', month)) AS transaction_year,
        EXTRACT(MONTH FROM PARSE_DATE('%Y-%m', month)) AS transaction_month,
        
        -- Location fields
        UPPER(TRIM(town)) AS town,
        UPPER(TRIM(street_name)) AS street_name,
        TRIM(block) AS block,
        
        -- Property characteristics
        UPPER(TRIM(flat_type)) AS flat_type,
        UPPER(TRIM(flat_model)) AS flat_model,
        UPPER(TRIM(storey_range)) AS storey_range,
        
        -- Numeric fields
        CAST(floor_area_sqm AS FLOAT64) AS floor_area_sqm,
        CAST(lease_commence_date AS INT64) AS lease_commence_date,
        CAST(resale_price AS FLOAT64) AS resale_price,
        
        -- Parse remaining lease
        TRIM(remaining_lease) AS remaining_lease_raw,
        CAST(REGEXP_EXTRACT(remaining_lease, r'(\d+) years') AS INT64) AS remaining_lease_years,
        CAST(REGEXP_EXTRACT(remaining_lease, r'(\d+) months') AS INT64) AS remaining_lease_months,
        
        -- Calculate total remaining lease in months
        CAST(REGEXP_EXTRACT(remaining_lease, r'(\d+) years') AS INT64) * 12 + 
        COALESCE(CAST(REGEXP_EXTRACT(remaining_lease, r'(\d+) months') AS INT64), 0) AS total_remaining_lease_months,
        
        -- Data quality flags
        CURRENT_TIMESTAMP() AS loaded_at
        
    FROM source_data
    WHERE resale_price IS NOT NULL
      AND floor_area_sqm IS NOT NULL
      AND floor_area_sqm > 0
      AND month IS NOT NULL
)

SELECT * FROM cleaned_data