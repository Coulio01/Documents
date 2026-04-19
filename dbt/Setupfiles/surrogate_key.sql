{#
  =============================================================================
  surrogate_key — Consistent surrogate key generation
  =============================================================================
  Generates a deterministic surrogate key by hashing a list of columns.
  Uses MD5 for Fabric SQL compatibility.

  Usage:
    {{ surrogate_key(['store_id', 'product_sku', 'sale_date']) }}
  =============================================================================
#}

{% macro surrogate_key(field_list) %}

  {%- set fields = [] -%}

  {%- for field in field_list -%}
    {%- set _ = fields.append(
        "COALESCE(CAST(" ~ field ~ " AS VARCHAR(100)), '_null_')"
    ) -%}
  {%- endfor -%}

  CONVERT(
    VARCHAR(32),
    HASHBYTES('MD5', {{ fields | join(" + '|' + ") }}),
    2
  )

{% endmacro %}
