{{ config(
    materialized='table',
    tags=['dimension']
) }}

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('2017-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}
),

date_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['date_month']) }} AS date_key,
        date_month AS date_value,
        EXTRACT(YEAR FROM date_month) AS year,
        EXTRACT(MONTH FROM date_month) AS month,
        EXTRACT(QUARTER FROM date_month) AS quarter,
        FORMAT_DATE('%B', date_month) AS month_name,
        FORMAT_DATE('%Y-%m', date_month) AS year_month,
        FORMAT_DATE('%Y-Q%Q', date_month) AS year_quarter,
        CASE WHEN EXTRACT(QUARTER FROM date_month) IN (1,2) THEN 'H1' ELSE 'H2' END AS half_year
    FROM date_spine
)

SELECT * FROM date_dimension