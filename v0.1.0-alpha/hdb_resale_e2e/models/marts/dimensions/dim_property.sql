{{ config(
    materialized='table',
    tags=['dimension']
) }}

WITH property_attributes AS (
    SELECT DISTINCT
        flat_type,
        flat_model,
        storey_range,
        -- Extract room count from flat_type
        CASE 
            WHEN flat_type LIKE '%1 ROOM%' THEN 1
            WHEN flat_type LIKE '%2 ROOM%' THEN 2
            WHEN flat_type LIKE '%3 ROOM%' THEN 3
            WHEN flat_type LIKE '%4 ROOM%' THEN 4
            WHEN flat_type LIKE '%5 ROOM%' THEN 5
            WHEN flat_type LIKE '%EXECUTIVE%' THEN 5
            WHEN flat_type LIKE '%MULTI%' THEN 6
            ELSE NULL
        END AS room_count,
        -- Categorize flat types
        CASE 
            WHEN flat_type IN ('1 ROOM', '2 ROOM') THEN 'Small'
            WHEN flat_type IN ('3 ROOM', '4 ROOM') THEN 'Medium'
            WHEN flat_type IN ('5 ROOM', 'EXECUTIVE') THEN 'Large'
            WHEN flat_type LIKE '%MULTI%' THEN 'Jumbo'
            ELSE 'Other'
        END AS flat_size_category,
        -- Extract storey information
        CASE 
            WHEN storey_range LIKE '%01 TO 03%' THEN 'Low'
            WHEN storey_range LIKE '%04 TO 06%' OR storey_range LIKE '%07 TO 09%' THEN 'Mid'
            WHEN storey_range LIKE '%10 TO 12%' OR storey_range LIKE '%13 TO 15%' THEN 'High'
            ELSE 'Very High'
        END AS storey_category,
        -- Parse storey range numbers
        CAST(REGEXP_EXTRACT(storey_range, r'(\d+) TO') AS INT64) AS storey_min,
        CAST(REGEXP_EXTRACT(storey_range, r'TO (\d+)') AS INT64) AS storey_max
    FROM {{ ref('stg_resale_transactions') }}
),

property_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['flat_type', 'flat_model', 'storey_range']) }} AS property_key,
        flat_type,
        flat_model,
        storey_range,
        room_count,
        flat_size_category,
        storey_category,
        storey_min,
        storey_max,
        CURRENT_TIMESTAMP() AS created_at
    FROM property_attributes
)

SELECT * FROM property_dimension