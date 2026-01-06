#!/bin/bash
set -e

DATA_YEAR=${DATA_YEAR:-2025}
TIGER_DIR="TIGER${DATA_YEAR}"

mkdir -p "/workspace/${TIGER_DIR}"

# Unzip all relevant files from mounted /tiger_data
find /tiger_data -name "*.zip" -exec unzip -d "/workspace/${TIGER_DIR}" {} \;

# Build the database using the new ogr2ogr-based import script
sudo build/tiger_import_ogr2ogr.sh /opt/geocoder.db "/workspace/${TIGER_DIR}"

# Clean up
sudo rm -r "/workspace/${TIGER_DIR}"
sudo build/rebuild_metaphones.sh /opt/geocoder.db
sudo chmod +x build/build_indexes.sh && sudo build/build_indexes.sh /opt/geocoder.db
sudo chmod +x build/rebuild_cluster.sh && sudo build/rebuild_cluster.sh /opt/geocoder.db

echo "Database build complete: /opt/geocoder.db"