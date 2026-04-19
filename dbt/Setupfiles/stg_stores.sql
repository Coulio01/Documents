-- =============================================================================
-- stg_stores — Staging: Store Master Data
-- Layer    : Silver (view on Lakehouse SQL endpoint)
-- Source   : bronze.raw_stores (static reference, refreshed weekly)
-- Purpose  : Standardise store reference data. One row per store_id.
-- =============================================================================

WITH source AS (
    SELECT * FROM {{ source('freshcart_raw', 'raw_stores') }}
),

cleaned AS (
    SELECT
        UPPER(TRIM(store_id))                       AS store_id,
        TRIM(store_name)                            AS store_name,
        TRIM(city)                                  AS city,
        INITCAP(TRIM(region))                       AS region,
        UPPER(TRIM(store_type))                     AS store_type,
        CAST(opening_date AS DATE)                  AS opening_date,
        _ingested_at,

        ROW_NUMBER() OVER (
            PARTITION BY UPPER(TRIM(store_id))
            ORDER BY _ingested_at DESC
        )                                           AS _row_num

    FROM source
    WHERE store_id IS NOT NULL
)

SELECT
    store_id,
    store_name,
    city,
    region,
    store_type,
    opening_date,
    _ingested_at
FROM cleaned
WHERE _row_num = 1
