-- =============================================================================
-- int_daily_sales — Intermediate: Daily Sales Aggregated by Store & Category
-- Layer    : Ephemeral (injected as CTE into downstream mart models)
-- Purpose  : Pre-aggregate sales at the store / product_category / day grain.
--            Joins sales with product attributes for enriched aggregation.
--            Not persisted — avoids redundant storage on small Fabric tiers.
-- =============================================================================

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales') }}
),

products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

joined AS (
    SELECT
        s.sale_date,
        s.sale_year,
        s.sale_month,
        s.sale_week,
        s.store_id,
        p.product_category,
        p.subcategory,
        p.brand,

        -- Transaction metrics
        COUNT(DISTINCT s.transaction_id)        AS transaction_count,
        COUNT(*)                                AS line_item_count,

        -- Volume metrics
        SUM(s.quantity_sold)                    AS total_units_sold,

        -- Revenue metrics
        SUM(s.gross_revenue)                    AS total_revenue,
        AVG(s.unit_price)                       AS avg_unit_price,
        MIN(s.unit_price)                       AS min_unit_price,
        MAX(s.unit_price)                       AS max_unit_price,

        -- Cost metrics (for margin calculation in marts)
        SUM(s.quantity_sold * p.unit_cost)      AS total_cost,

        -- Payment split
        SUM(CASE WHEN s.payment_method = 'CASH'   THEN s.gross_revenue ELSE 0 END) AS revenue_cash,
        SUM(CASE WHEN s.payment_method = 'CARD'   THEN s.gross_revenue ELSE 0 END) AS revenue_card,
        SUM(CASE WHEN s.payment_method = 'ONLINE' THEN s.gross_revenue ELSE 0 END) AS revenue_online,

        -- Loyalty split
        SUM(CASE WHEN s.customer_id != 'ANONYMOUS' THEN s.gross_revenue ELSE 0 END) AS revenue_loyalty,
        SUM(CASE WHEN s.customer_id  = 'ANONYMOUS' THEN s.gross_revenue ELSE 0 END) AS revenue_anonymous

    FROM sales s
    LEFT JOIN products p
        ON s.product_sku = p.sku
    GROUP BY
        s.sale_date,
        s.sale_year,
        s.sale_month,
        s.sale_week,
        s.store_id,
        p.product_category,
        p.subcategory,
        p.brand
)

SELECT * FROM joined
