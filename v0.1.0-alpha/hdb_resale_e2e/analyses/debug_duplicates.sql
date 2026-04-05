WITH key_analysis AS (
    SELECT 
        month, town, street_name, block, flat_type, storey_range, 
        floor_area_sqm, flat_model, lease_commence_date, remaining_lease, resale_price,
        COUNT(*) as record_count
    FROM {{ source('hdb_resale_raw', 'clean_hdb_resale_file') }}
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11
    HAVING COUNT(*) > 1
    ORDER BY record_count DESC
    LIMIT 10
)

SELECT 
    'Records with identical all fields' as issue_type,
    COUNT(*) as group_count,
    SUM(record_count) as total_records
FROM key_analysis

UNION ALL

-- Check partial field combinations
SELECT 
    'Check if missing flat_model/lease dates cause issues' as issue_type,
    COUNT(*) as group_count,
    0 as total_records
FROM (
    SELECT 
        month, town, street_name, block, flat_type, storey_range, 
        floor_area_sqm, resale_price,
        COUNT(*) as record_count
    FROM {{ source('hdb_resale_raw', 'clean_hdb_resale_file') }}
    GROUP BY 1,2,3,4,5,6,7,8
    HAVING COUNT(*) > 1
) partial_check