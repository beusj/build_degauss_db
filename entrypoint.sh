#!/bin/bash
set -e

DATA_YEAR=${DATA_YEAR:-2025}

# Build the database using ogr2ogr, which reads directly from ZIP files
# No need to unzip - ogr2ogr uses GDAL's /vsizip/ virtual filesystem
sudo build/tiger_import_ogr2ogr.sh /opt/geocoder.db "/tiger_data"
sudo build/rebuild_metaphones.sh /opt/geocoder.db
sudo chmod +x build/build_indexes.sh && sudo build/build_indexes.sh /opt/geocoder.db
sudo chmod +x build/rebuild_cluster.sh && sudo build/rebuild_cluster.sh /opt/geocoder.db

echo "Database build complete: /opt/geocoder.db"