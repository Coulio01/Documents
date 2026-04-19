-- =============================================================================
-- int_inventory_status — Intermediate: Enriched Inventory Snapshot
-- Layer    : Ephemeral (injected as CTE into downstream mart models)
-- Purpose  : Join inventory snapshots with product and store master data.
--            Compute days-of-supply and flag items needing immediate action.
-- =============================================================================

WITH inventory AS (
    SELECT * FROM {{ ref('stg_inventory') }}
),

products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

stores AS (
    SELECT * FROM {{ ref('stg_stores') }}
),

-- Average daily sales per store/product over last 30 days
-- (used to calculate days of supply)
recent_sales AS (
    SELECT
        store_id,
        product_sku,
        AVG(CAST(quantity_sold AS FLOAT))   AS avg_daily_units_sold
    FROM {{ ref('stg_sales') }}
    WHERE sale_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
    GROUP BY store_id, product_sku
),

joined AS (
    SELECT
        -- Keys
        i.snapshot_date,
        i.store_id,
        i.product_sku,

        -- Product attributes
        p.product_name,
        p.product_category,
        p.subcategory,
        p.brand,
        p.unit_cost,

        -- Store attributes
        s.store_name,
        s.city,
        s.region,
        s.store_type,

        -- Inventory measures
        i.quantity_on_hand,
        i.reorder_point,
        i.stock_status,
        i.needs_reorder,

        -- Days of supply: how many days until stock runs out
        CASE
            WHEN COALESCE(rs.avg_daily_units_sold, 0) = 0 THEN NULL
            ELSE CAST(i.quantity_on_hand AS FLOAT)
                 / rs.avg_daily_units_sold
        END                                         AS days_of_supply,

        -- Stock value on hand
        CAST(i.quantity_on_hand AS DECIMAL(10,2))
            * COALESCE(p.unit_cost, 0)              AS stock_value_eur,

        -- Priority reorder flag: out of stock OR less than 3 days supply
        CASE
            WHEN i.stock_status = 'OUT_OF_STOCK' THEN 1
            WHEN (CAST(i.quantity_on_hand AS FLOAT)
                  / NULLIF(rs.avg_daily_units_sold, 0)) < 3 THEN 1
            ELSE 0
        END                                         AS urgent_reorder_flag

    FROM inventory i
    LEFT JOIN products  p  ON i.product_sku = p.sku
    LEFT JOIN stores    s  ON i.store_id    = s.store_id
    LEFT JOIN recent_sales rs
           ON i.store_id    = rs.store_id
          AND i.product_sku = rs.product_sku
)

SELECT * FROM joined
