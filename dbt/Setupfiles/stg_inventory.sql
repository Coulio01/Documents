-- =============================================================================
-- stg_inventory — Staging: Daily Inventory Snapshots
-- Layer    : Silver (view on Lakehouse SQL endpoint)
-- Source   : bronze.raw_inventory (ERP Navision nightly export)
-- Purpose  : Clean and enrich daily end-of-day inventory records.
--            One row per store per product per day.
-- =============================================================================

WITH source AS (
    SELECT * FROM {{ source('freshcart_raw', 'raw_inventory') }}
),

cleaned AS (
    SELECT
        -- Keys
        TRIM(store_id)                              AS store_id,
        TRIM(product_sku)                           AS product_sku,
        CAST(snapshot_date      AS DATE)            AS snapshot_date,

        -- Measures
        CAST(quantity_on_hand   AS INT)             AS quantity_on_hand,
        CAST(reorder_point      AS INT)             AS reorder_point,

        -- Derived flags
        CASE
            WHEN CAST(quantity_on_hand AS INT) = 0            THEN 'OUT_OF_STOCK'
            WHEN CAST(quantity_on_hand AS INT)
               < CAST(reorder_point    AS INT)                THEN 'LOW_STOCK'
            ELSE                                                   'ADEQUATE'
        END                                         AS stock_status,

        CASE
            WHEN CAST(quantity_on_hand AS INT)
               < CAST(reorder_point    AS INT) THEN 1 ELSE 0
        END                                         AS needs_reorder,

        -- Metadata
        _ingested_at

    FROM source
    WHERE
        snapshot_date IS NOT NULL
        AND store_id  IS NOT NULL
        AND product_sku IS NOT NULL
)

SELECT * FROM cleaned
