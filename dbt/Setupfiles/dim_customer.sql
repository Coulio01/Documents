-- =============================================================================
-- dim_customer — Mart: Customer Dimension
-- Layer    : Gold (persisted table in Fabric Data Warehouse, finance schema)
-- Grain    : One row per loyalty customer
-- Consumers: Marketing Power BI reports, customer segmentation
-- =============================================================================

{{
  config(
    materialized = 'table',
    schema       = 'finance',
    tags         = ['dimension', 'customer', 'marketing']
  )
}}

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

-- Aggregate lifetime purchase behaviour per customer
customer_sales AS (
    SELECT
        customer_id,
        COUNT(DISTINCT transaction_id)  AS total_transactions,
        SUM(gross_revenue)              AS lifetime_value,
        MAX(sale_date)                  AS last_purchase_date,
        MIN(sale_date)                  AS first_purchase_date,
        AVG(gross_revenue)              AS avg_basket_value
    FROM {{ ref('stg_sales') }}
    WHERE customer_id != 'ANONYMOUS'
    GROUP BY customer_id
),

final AS (
    SELECT
        -- Surrogate key
        {{ surrogate_key(['c.customer_id']) }}       AS customer_key,

        -- Natural key
        c.customer_id,

        -- Identity (non-sensitive fields only in this layer)
        c.first_name,
        c.last_name,
        c.city,
        c.postal_code,

        -- Loyalty attributes
        c.registration_date,
        c.opted_in_marketing,
        c.tenure_days,

        -- Purchase behaviour (from sales aggregation)
        COALESCE(cs.total_transactions, 0)          AS total_transactions,
        COALESCE(cs.lifetime_value, 0)              AS lifetime_value_eur,
        cs.last_purchase_date,
        cs.first_purchase_date,
        COALESCE(cs.avg_basket_value, 0)            AS avg_basket_value_eur,

        -- RFM-inspired segments
        CASE
            WHEN cs.last_purchase_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
             AND cs.total_transactions >= 10        THEN 'Champion'
            WHEN cs.last_purchase_date >= DATEADD(DAY, -60, CAST(GETDATE() AS DATE))
             AND cs.total_transactions >= 5         THEN 'Loyal'
            WHEN cs.last_purchase_date >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE)) THEN 'At Risk'
            WHEN cs.last_purchase_date IS NULL      THEN 'Never Purchased'
            ELSE                                         'Lapsed'
        END                                         AS customer_segment,

        -- Metadata
        GETDATE()                                   AS _model_refreshed_at

    FROM customers c
    LEFT JOIN customer_sales cs
        ON c.customer_id = cs.customer_id
)

SELECT * FROM final
