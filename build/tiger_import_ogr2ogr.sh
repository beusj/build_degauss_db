#!/bin/bash

SHPS="edges"
DBFS="featnames addr"
BASE=$(dirname $0)
SQL="$BASE/sql"
HELPER_LIB="$BASE/../lib/geocoder/us/sqlite3.so"
DATABASE=$1
SOURCE=$2
shift
shift

# Initialize the database if it doesn't exist.
[ ! -r $DATABASE ] && cat ${SQL}/{create,place}.sql | sqlite3 $DATABASE

# Marshal the county directories to import.
if [ x"$1" != x"" ]; then
    cat
else
    # Find all county IDs from the directory structure
    ls $SOURCE/tl_*_edges.zip 2>/dev/null | while read file; do
        file=$(basename $file)
        code=${file##tl_????_}
        echo ${code%%_edges.zip}
    done
fi | sort | while read code; do
    echo "--- $code"
    
    # Use ogr2ogr to import shapefiles and DBF files directly from ZIP archives
    # GDAL's /vsizip/ virtual filesystem allows reading from ZIP without unzipping
    
    for file in $SHPS; do
        ZIP=$(ls $SOURCE/*_${code}_${file}.zip 2>/dev/null | head -1)
        if [ -n "$ZIP" ]; then
            # Find the .shp file inside the ZIP
            SHP_NAME=$(unzip -l "$ZIP" "*.shp" 2>/dev/null | grep -oP '[^ ]+\.shp$' | head -1)
            if [ -n "$SHP_NAME" ]; then
                echo "Importing shapefile from ZIP: $ZIP"
                ogr2ogr -f SQLite -update -append "$DATABASE" "/vsizip/$ZIP/$SHP_NAME" \
                    -nln "tiger_${file}" \
                    -skipfailures \
                    -lco GEOMETRY_NAME=geom
            fi
        fi
    done
    
    # For DBF-only files (no geometry), use ogr2ogr without geometry
    for file in $DBFS; do
        ZIP=$(ls $SOURCE/*_${code}_${file}.zip 2>/dev/null | head -1)
        if [ -n "$ZIP" ]; then
            # Find the .dbf file inside the ZIP
            DBF_NAME=$(unzip -l "$ZIP" "*.dbf" 2>/dev/null | grep -oP '[^ ]+\.dbf$' | head -1)
            if [ -n "$DBF_NAME" ]; then
                echo "Importing DBF file from ZIP: $ZIP"
                ogr2ogr -f SQLite -update -append "$DATABASE" "/vsizip/$ZIP/$DBF_NAME" \
                    -nln "tiger_${file}" \
                    -skipfailures
            fi
        fi
    done
    
    # Run the ETL transformation
    echo "Running ETL transformations..."
    (echo ".load $HELPER_LIB" && \
     cat ${SQL}/setup.sql && \
     cat ${SQL}/convert.sql) | sqlite3 $DATABASE
    
done 2>&1 | tee import-$$.log
