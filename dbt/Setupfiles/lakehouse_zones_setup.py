# =============================================================================
# lakehouse_zones_setup.py
# Run this as a Fabric Notebook (PySpark kernel) ONCE per environment
# to create the Bronze / Silver / Gold folder structure in OneLake.
# =============================================================================

from pyspark.sql import SparkSession
import notebookutils           # Available natively in Fabric notebooks

spark = SparkSession.builder.getOrCreate()

# ---------------------------------------------------------------------------
# Configuration — update these for each environment (dev / test / prod)
# ---------------------------------------------------------------------------
LAKEHOUSE_NAME = "FreshCart_Lakehouse"   # Your Lakehouse name in Fabric
ENVIRONMENT    = "prod"                  # dev | test | prod

# ---------------------------------------------------------------------------
# OneLake path — Fabric mounts the Lakehouse at /lakehouse/default
# ---------------------------------------------------------------------------
BASE_PATH = f"Files"    # root of the Files section in the Lakehouse

ZONES = {
    "bronze": [
        "raw_sales_transactions",
        "raw_inventory",
        "raw_products",
        "raw_customers",
        "raw_stores",
    ],
    "silver": [],        # Managed by dbt views — no folders needed
    "gold":   [],        # Managed by Fabric Data Warehouse — no folders needed
}

# ---------------------------------------------------------------------------
# Create Bronze zone folder structure
# ---------------------------------------------------------------------------
print(f"Setting up Lakehouse zones for: {LAKEHOUSE_NAME} [{ENVIRONMENT}]")
print("-" * 60)

for zone, subfolders in ZONES.items():
    zone_path = f"abfss://{LAKEHOUSE_NAME}@onelake.dfs.fabric.microsoft.com/{BASE_PATH}/{zone}"
    print(f"\n📁 Zone: {zone}")

    # Create zone root
    try:
        notebookutils.fs.mkdirs(zone_path)
        print(f"   ✅ Created: {zone}/")
    except Exception as e:
        print(f"   ℹ️  Already exists or skipped: {zone}/ ({e})")

    # Create subfolders for source tables (bronze only)
    for subfolder in subfolders:
        folder_path = f"{zone_path}/{subfolder}"
        try:
            notebookutils.fs.mkdirs(folder_path)
            print(f"   ✅ Created: {zone}/{subfolder}/")
        except Exception as e:
            print(f"   ℹ️  Already exists: {zone}/{subfolder}/ ({e})")

# ---------------------------------------------------------------------------
# Create a _schema.json marker in each bronze subfolder
# This helps Data Factory pipelines discover target paths automatically
# ---------------------------------------------------------------------------
print("\n📋 Writing schema marker files to bronze subfolders...")

schema_markers = {
    "raw_sales_transactions": {
        "source": "POS System",
        "load_frequency": "nightly",
        "format": "parquet",
        "partition_by": "sale_date"
    },
    "raw_inventory": {
        "source": "ERP Navision",
        "load_frequency": "nightly",
        "format": "parquet",
        "partition_by": "snapshot_date"
    },
    "raw_products": {
        "source": "ERP Navision",
        "load_frequency": "weekly",
        "format": "parquet",
        "partition_by": None
    },
    "raw_customers": {
        "source": "Loyalty + E-commerce",
        "load_frequency": "nightly",
        "format": "parquet",
        "partition_by": None
    },
    "raw_stores": {
        "source": "ERP Navision",
        "load_frequency": "weekly",
        "format": "parquet",
        "partition_by": None
    },
}

import json

for table, meta in schema_markers.items():
    marker_path = f"abfss://{LAKEHOUSE_NAME}@onelake.dfs.fabric.microsoft.com/{BASE_PATH}/bronze/{table}/_schema.json"
    meta["table"] = table
    meta["environment"] = ENVIRONMENT
    meta["created_by"] = "lakehouse_zones_setup.py"

    try:
        notebookutils.fs.put(marker_path, json.dumps(meta, indent=2), overwrite=True)
        print(f"   ✅ Marker: bronze/{table}/_schema.json")
    except Exception as e:
        print(f"   ⚠️  Could not write marker for {table}: {e}")

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print("\n" + "=" * 60)
print("✅ Lakehouse zone setup complete.")
print(f"   Lakehouse : {LAKEHOUSE_NAME}")
print(f"   Environment: {ENVIRONMENT}")
print(f"   Bronze subfolders created: {len(schema_markers)}")
print("\nNext steps:")
print("  1. Configure Data Factory pipelines to land files in bronze/<table>/")
print("  2. Run dbt to build Silver views on top of bronze tables")
print("  3. Run dbt build --select marts to populate the Data Warehouse gold layer")
print("=" * 60)
