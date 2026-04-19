{#
  =============================================================================
  generate_schema_name — Multi-environment schema routing
  =============================================================================
  Purpose:
    By default dbt appends the custom schema to the target schema, producing
    names like  dbo_silver  or  dbo_gold.  This macro overrides that behaviour
    so that:
      - In PROD  : schema = custom_schema_name  (e.g. "silver", "gold")
      - In DEV   : schema = <dev_prefix>_<custom_schema>  (e.g. "jane_silver")
      - No schema: falls back to target.schema  (e.g. "dbo")

  This ensures prod models land in clean schemas (silver / gold) while dev
  models are isolated per developer and never overwrite each other.
  =============================================================================
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

  {%- set default_schema = target.schema -%}

  {%- if custom_schema_name is none -%}

    {{ default_schema }}

  {%- elif target.name == 'prod' -%}

    {# In production use the schema exactly as declared in dbt_project.yml #}
    {{ custom_schema_name | trim }}

  {%- elif target.name == 'test' -%}

    {# In test prefix with 'test_' to keep schemas clearly identifiable #}
    test_{{ custom_schema_name | trim }}

  {%- else -%}

    {# In dev isolate per developer using their target schema as a prefix #}
    {{ default_schema }}_{{ custom_schema_name | trim }}

  {%- endif -%}

{%- endmacro %}
