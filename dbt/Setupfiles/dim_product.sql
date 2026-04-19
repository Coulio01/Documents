-- =============================================================================
-- dim_product — Mart: Product Dimension
-- Layer    : Gold (persisted table in Fabric Data Warehouse, finance schema)
-- Grain    : One row per unique product SKU
-- Consumers: All Power BI reports requiring product slicing
-- =============================================================================

{{
  config(
    materialized = 'table',
    schema       = 'finance',
    tags         = ['dimension', 'product']
  )
}}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

final AS (
    SELECT
        -- Surrogate key
        {{ surrogate_key(['sku']) }}     AS product_key,

        -- Natural key
        sku                             AS product_sku,

        -- Attributes
        product_name,
        product_category,
        subcategory,
        brand,
        supplier_id,
        unit_cost,

        -- Derived tier (for reporting groupings)
        CASE
            WHEN unit_cost < 1.00  THEN 'Budget'
            WHEN unit_cost < 5.00  THEN 'Standard'
            WHEN unit_cost < 15.00 THEN 'Premium'
            ELSE                        'Luxury'
        END                             AS price_tier,

        -- Metadata
        _ingested_at                    AS _source_updated_at,
        GETDATE()                       AS _model_refreshed_at

    FROM products
)

SELECT * FROM final
