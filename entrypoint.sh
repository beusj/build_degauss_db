#!/bin/bash
set -e

DATA_YEAR=${DATA_YEAR:-2025}
TIGER_DIR="TIGER${DATA_YEAR}"

mkdir -p "/workspace/${TIGER_DIR}"

# Unzip all relevant files from mounted /tiger_data
find /tiger_data -name "*.zip" -exec unzip -d "/workspace/${TIGER_DIR}" {} \;

# Build the database
sudo build/tiger_import /opt/geocoder.db "/workspace/${TIGER_DIR}"

# Clean up
sudo rm -r "/workspace/${TIGER_DIR}"
sudo build/rebuild_metaphones /opt/geocoder.db
sudo chmod +x build/build_indexes && sudo build/build_indexes /opt/geocoder.db
sudo chmod +x build/rebuild_cluster && sudo build/rebuild_cluster /opt/geocoder.db

echo "Database build complete: /opt/geocoder.db"