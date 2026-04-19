-- =============================================================================
-- assert_margin_not_above_100pct
-- Custom singular test: gross margin percentage should never exceed 100%.
-- A margin above 100% means cost data is missing or zero — a data quality gap.
-- This test PASSES when it returns 0 rows.
-- =============================================================================

SELECT
    revenue_key,
    sale_date,
    store_id,
    product_category,
    total_revenue,
    total_cost,
    gross_margin_pct
FROM {{ ref('fact_daily_revenue') }}
WHERE gross_margin_pct > 100
  AND total_revenue > 0   -- only flag records where revenue is real
