-- =============================================================================
-- assert_inventory_non_negative
-- Custom singular test: ensures quantity_on_hand is never negative.
-- Negative inventory is physically impossible and indicates an ERP sync error.
-- This test PASSES when it returns 0 rows.
-- =============================================================================

SELECT
    store_id,
    product_sku,
    snapshot_date,
    quantity_on_hand
FROM {{ ref('stg_inventory') }}
WHERE quantity_on_hand < 0
