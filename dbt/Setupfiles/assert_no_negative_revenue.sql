-- =============================================================================
-- assert_no_negative_revenue
-- Custom singular test: ensures no negative gross_revenue exists in stg_sales.
-- A negative value indicates a data pipeline error or unhandled refund record.
-- This test PASSES when it returns 0 rows.
-- =============================================================================

SELECT
    transaction_id,
    store_id,
    product_sku,
    sale_date,
    gross_revenue
FROM {{ ref('stg_sales') }}
WHERE gross_revenue < 0
