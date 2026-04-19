-- =============================================================================
-- dim_store — Mart: Store Dimension
-- Layer    : Gold (persisted table in Fabric Data Warehouse, finance schema)
-- Grain    : One row per store
-- Consumers: All Power BI reports requiring store slicing
-- =============================================================================

{{
  config(
    materialized = 'table',
    schema       = 'finance',
    tags         = ['dimension', 'store']
  )
}}

WITH stores AS (
    SELECT * FROM {{ ref('stg_stores') }}
),

final AS (
    SELECT
        -- Surrogate key
        {{ surrogate_key(['store_id']) }}    AS store_key,

        -- Natural key
        store_id,

        -- Attributes
        store_name,
        city,
        region,
        store_type,
        opening_date,

        -- Derived: how many years the store has been open
        DATEDIFF(YEAR, opening_date, CAST(GETDATE() AS DATE))
                                            AS years_open,

        -- Metadata
        _ingested_at                        AS _source_updated_at,
        GETDATE()                           AS _model_refreshed_at

    FROM stores
)

SELECT * FROM final
