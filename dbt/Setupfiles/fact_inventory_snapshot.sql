-- =============================================================================
-- fact_inventory_snapshot — Mart: Daily Inventory Fact
-- Layer    : Gold (persisted table in Fabric Data Warehouse, operations schema)
-- Grain    : One row per store / product / day
-- Consumers: Operations team Power BI reports, reorder alerts
-- =============================================================================

{{
  config(
    materialized = 'table',
    schema       = 'operations',
    tags         = ['operations', 'inventory', 'daily']
  )
}}

WITH inventory AS (
    SELECT * FROM {{ ref('int_inventory_status') }}
),

final AS (
    SELECT
        -- Surrogate key
        {{ surrogate_key(['snapshot_date', 'store_id', 'product_sku']) }}
                                                    AS inventory_key,

        -- Dimensions
        snapshot_date,
        store_id,
        store_name,
        city,
        region,
        store_type,
        product_sku,
        product_name,
        product_category,
        subcategory,
        brand,

        -- Inventory measures
        quantity_on_hand,
        reorder_point,
        stock_status,
        needs_reorder,
        urgent_reorder_flag,
        days_of_supply,
        stock_value_eur,
        unit_cost,

        -- Week-over-week stock change (window function)
        quantity_on_hand - LAG(quantity_on_hand, 7) OVER (
            PARTITION BY store_id, product_sku
            ORDER BY snapshot_date
        )                                           AS wow_stock_change,

        -- Metadata
        GETDATE()                                   AS _model_refreshed_at

    FROM inventory
)

SELECT * FROM final
