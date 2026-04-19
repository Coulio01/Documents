-- =============================================================================
-- fact_daily_revenue — Mart: Daily Revenue Fact Table
-- Layer    : Gold (persisted table in Fabric Data Warehouse, finance schema)
-- Grain    : One row per store / product_category / day
-- Consumers: Finance team Power BI reports
-- =============================================================================

{{
  config(
    materialized  = 'table',
    schema        = 'finance',
    tags          = ['finance', 'daily', 'revenue'],
    post_hook     = [
      "CREATE INDEX IF NOT EXISTS idx_fdr_date     ON {{ this }} (sale_date)",
      "CREATE INDEX IF NOT EXISTS idx_fdr_store    ON {{ this }} (store_id)",
      "CREATE INDEX IF NOT EXISTS idx_fdr_category ON {{ this }} (product_category)"
    ]
  )
}}

WITH daily_sales AS (
    SELECT * FROM {{ ref('int_daily_sales') }}
),

stores AS (
    SELECT * FROM {{ ref('stg_stores') }}
),

enriched AS (
    SELECT
        -- Surrogate key
        {{ surrogate_key(['ds.sale_date', 'ds.store_id', 'ds.product_category', 'ds.brand']) }}
                                                    AS revenue_key,

        -- Date dimension
        ds.sale_date,
        ds.sale_year,
        ds.sale_month,
        ds.sale_week,
        DATENAME(WEEKDAY, ds.sale_date)             AS sale_day_name,
        CASE
            WHEN DATEPART(WEEKDAY, ds.sale_date) IN (1, 7) THEN 1
            ELSE 0
        END                                         AS is_weekend,

        -- Store dimension
        ds.store_id,
        st.store_name,
        st.city,
        st.region,
        st.store_type,

        -- Product dimension
        ds.product_category,
        ds.subcategory,
        ds.brand,

        -- Revenue measures
        ds.total_revenue,
        ds.total_units_sold,
        ds.transaction_count,
        ds.line_item_count,
        ds.avg_unit_price,

        -- Margin measures
        ds.total_cost,
        ds.total_revenue - ds.total_cost            AS gross_margin,
        CASE
            WHEN ds.total_revenue = 0 THEN NULL
            ELSE (ds.total_revenue - ds.total_cost) / ds.total_revenue * 100
        END                                         AS gross_margin_pct,

        -- Payment channel split
        ds.revenue_cash,
        ds.revenue_card,
        ds.revenue_online,

        -- Loyalty split
        ds.revenue_loyalty,
        ds.revenue_anonymous,

        -- Running totals (window functions — supported in Fabric DW)
        SUM(ds.total_revenue) OVER (
            PARTITION BY ds.store_id
            ORDER BY ds.sale_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                           AS cumulative_revenue_store,

        SUM(ds.total_revenue) OVER (
            PARTITION BY ds.sale_year, ds.store_id
            ORDER BY ds.sale_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                           AS ytd_revenue_store,

        -- Metadata
        GETDATE()                                   AS _model_refreshed_at

    FROM daily_sales ds
    LEFT JOIN stores st
        ON ds.store_id = st.store_id
)

SELECT * FROM enriched
