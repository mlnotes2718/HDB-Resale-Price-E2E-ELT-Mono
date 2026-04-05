{{ config(
    materialized='table',
    tags=['dimension']
) }}

WITH location_hierarchy AS (
    SELECT DISTINCT
        town,
        street_name,
        -- Add regional groupings based on Singapore geography
        CASE 
            WHEN town IN ('ANG MO KIO', 'BISHAN', 'HOUGANG', 'PUNGGOL', 'SENGKANG', 'SERANGOON', 'THOMSON') THEN 'North East'
            WHEN town IN ('BEDOK', 'PASIR RIS', 'TAMPINES') THEN 'East'
            WHEN town IN ('BUKIT BATOK', 'BUKIT PANJANG', 'CHOA CHU KANG', 'CLEMENTI', 'JURONG EAST', 'JURONG WEST') THEN 'West'
            WHEN town IN ('BUKIT MERAH', 'CENTRAL AREA', 'QUEENSTOWN', 'TOA PAYOH') THEN 'Central'
            WHEN town IN ('KALLANG/WHAMPOA', 'MARINE PARADE', 'GEYLANG') THEN 'Central East'
            ELSE 'Other'
        END AS region,
        -- Classify by development type
        CASE 
            WHEN town = 'CENTRAL AREA' THEN 'CBD'
            WHEN town IN ('BISHAN', 'ANG MO KIO', 'TOA PAYOH') THEN 'Mature Estate'
            WHEN town IN ('PUNGGOL', 'SENGKANG') THEN 'New Town'
            ELSE 'Established Town'
        END AS town_category
    FROM {{ ref('stg_resale_transactions') }}
),

location_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['town', 'street_name']) }} AS location_key,
        town,
        street_name,
        region,
        town_category,
        CURRENT_TIMESTAMP() AS created_at
    FROM location_hierarchy
)

SELECT * FROM location_dimension