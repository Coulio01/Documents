-- =============================================================================
-- stg_customers — Staging: Loyalty Customer Profiles
-- Layer    : Silver (view on Lakehouse SQL endpoint)
-- Source   : bronze.raw_customers (loyalty + e-commerce platform)
-- Purpose  : Clean PII fields, standardise formats, deduplicate.
--            One row per unique customer_id.
-- =============================================================================

WITH source AS (
    SELECT * FROM {{ source('freshcart_raw', 'raw_customers') }}
),

cleaned AS (
    SELECT
        -- Keys
        TRIM(customer_id)                           AS customer_id,

        -- PII — trimmed and title-cased
        TRIM(first_name)                            AS first_name,
        TRIM(last_name)                             AS last_name,
        LOWER(TRIM(email))                          AS email,

        -- Location
        TRIM(city)                                  AS city,
        TRIM(postal_code)                           AS postal_code,

        -- Dates
        CAST(registration_date AS DATE)             AS registration_date,

        -- Flags
        CAST(opted_in_marketing AS BIT)             AS opted_in_marketing,

        -- Derived: customer tenure in days (at time of loading)
        DATEDIFF(
            DAY,
            CAST(registration_date AS DATE),
            CAST(GETDATE() AS DATE)
        )                                           AS tenure_days,

        -- Metadata
        _ingested_at,

        -- Deduplication
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(customer_id)
            ORDER BY _ingested_at DESC
        )                                           AS _row_num

    FROM source
    WHERE customer_id IS NOT NULL
),

final AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        city,
        postal_code,
        registration_date,
        opted_in_marketing,
        tenure_days,
        _ingested_at
    FROM cleaned
    WHERE _row_num = 1
)

SELECT * FROM final
