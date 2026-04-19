-- =============================================================================
-- stg_sales — Staging: Sales Transactions
-- Layer    : Silver (view on Lakehouse SQL endpoint)
-- Source   : bronze.raw_sales_transactions (POS system)
-- Purpose  : Clean, type-cast and standardise raw POS transaction records.
--            One row per line item per transaction.
-- =============================================================================

WITH source AS (
    SELECT * FROM {{ source('freshcart_raw', 'raw_sales_transactions') }}
),

cleaned AS (
    SELECT
        -- Keys
        CAST(transaction_id     AS BIGINT)          AS transaction_id,
        TRIM(store_id)                              AS store_id,
        TRIM(product_sku)                           AS product_sku,
        COALESCE(TRIM(customer_id), 'ANONYMOUS')    AS customer_id,

        -- Dates & timestamps
        CAST(sale_date          AS DATE)            AS sale_date,
        DATEPART(YEAR,  sale_date)                  AS sale_year,
        DATEPART(MONTH, sale_date)                  AS sale_month,
        DATEPART(WEEK,  sale_date)                  AS sale_week,

        -- Measures
        CAST(quantity_sold      AS INT)             AS quantity_sold,
        CAST(unit_price         AS DECIMAL(10, 2))  AS unit_price,
        CAST(quantity_sold AS DECIMAL(10, 2))
            * CAST(unit_price AS DECIMAL(10, 2))   AS gross_revenue,

        -- Categorical
        UPPER(TRIM(payment_method))                 AS payment_method,

        -- Metadata
        _ingested_at

    FROM source
    WHERE
        transaction_id  IS NOT NULL
        AND sale_date   IS NOT NULL
        AND quantity_sold > 0       -- exclude voided/zero-qty lines
        AND unit_price  >= 0        -- exclude data errors
)

SELECT * FROM cleaned
