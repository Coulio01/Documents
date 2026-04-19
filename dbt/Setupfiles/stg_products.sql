-- =============================================================================
-- stg_products — Staging: Product Master Data
-- Layer    : Silver (view on Lakehouse SQL endpoint)
-- Source   : bronze.raw_products (ERP Navision weekly export)
-- Purpose  : Standardise product master data. One row per unique SKU.
-- =============================================================================

WITH source AS (
    SELECT * FROM {{ source('freshcart_raw', 'raw_products') }}
),

cleaned AS (
    SELECT
        -- Keys
        UPPER(TRIM(sku))                            AS sku,
        TRIM(supplier_id)                           AS supplier_id,

        -- Descriptors
        TRIM(product_name)                          AS product_name,
        INITCAP(TRIM(product_category))             AS product_category,
        INITCAP(TRIM(subcategory))                  AS subcategory,
        COALESCE(TRIM(brand), 'Private Label')      AS brand,

        -- Financials
        CAST(unit_cost AS DECIMAL(10, 2))           AS unit_cost,

        -- Metadata
        _ingested_at,

        -- Deduplication — keep the most recently ingested record per SKU
        ROW_NUMBER() OVER (
            PARTITION BY UPPER(TRIM(sku))
            ORDER BY _ingested_at DESC
        )                                           AS _row_num

    FROM source
    WHERE sku IS NOT NULL
)

SELECT
    sku,
    supplier_id,
    product_name,
    product_category,
    subcategory,
    brand,
    unit_cost,
    _ingested_at
FROM cleaned
WHERE _row_num = 1
