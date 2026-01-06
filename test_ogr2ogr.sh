#!/bin/bash
set -e

# Test script for ogr2ogr implementation
# Tests a single county (01001) to verify the import works correctly
# Uses GDAL's /vsizip/ virtual filesystem to read directly from ZIP files

TEST_DB="test_output.db"
TEST_DATA="tiger_data/01"
BUILD_DIR="build"
HELPER_LIB="lib/geocoder/us/sqlite3.so"

echo "================================"
echo "Testing ogr2ogr TIGER import"
echo "================================"

# Clean up old test database if it exists
if [ -f "$TEST_DB" ]; then
    echo "Removing old test database..."
    rm "$TEST_DB"
fi

# Verify prerequisites
if ! command -v ogr2ogr &> /dev/null; then
    echo "ERROR: ogr2ogr not found. Install GDAL/ogr2ogr first."
    exit 1
fi

if ! command -v sqlite3 &> /dev/null; then
    echo "ERROR: sqlite3 not found."
    exit 1
fi

echo ""
echo "1. Initializing test database..."
cat "$BUILD_DIR/sql/create.sql" | sqlite3 "$TEST_DB"
cat "$BUILD_DIR/sql/place.sql" | sqlite3 "$TEST_DB"

echo ""
echo "2. Testing import for county 01001 (Autauga, AL)..."

# Use ogr2ogr with /vsizip/ to read directly from ZIP files (no unzipping needed!)
echo ""
echo "Importing edges shapefile from ZIP..."
EDGES_ZIP="$TEST_DATA/tl_2025_01001_edges.zip"
EDGES_SHP=$(unzip -l "$EDGES_ZIP" "*.shp" 2>/dev/null | grep -oP '[^ ]+\.shp$' | head -1)
if [ -n "$EDGES_SHP" ]; then
    ogr2ogr -f SQLite -update -append "$TEST_DB" "/vsizip/$EDGES_ZIP/$EDGES_SHP" \
        -nln "tiger_edges" \
        -skipfailures \
        -lco GEOMETRY_NAME=geom
else
    echo "ERROR: Could not find .shp file in $EDGES_ZIP"
    exit 1
fi

echo "Importing addr DBF from ZIP..."
ADDR_ZIP="$TEST_DATA/tl_2025_01001_addr.zip"
ADDR_DBF=$(unzip -l "$ADDR_ZIP" "*.dbf" 2>/dev/null | grep -oP '[^ ]+\.dbf$' | head -1)
if [ -n "$ADDR_DBF" ]; then
    ogr2ogr -f SQLite -update -append "$TEST_DB" "/vsizip/$ADDR_ZIP/$ADDR_DBF" \
        -nln "tiger_addr" \
        -skipfailures
else
    echo "ERROR: Could not find .dbf file in $ADDR_ZIP"
    exit 1
fi

echo "Importing featnames DBF from ZIP..."
FEATNAMES_ZIP="$TEST_DATA/tl_2025_01001_featnames.zip"
FEATNAMES_DBF=$(unzip -l "$FEATNAMES_ZIP" "*.dbf" 2>/dev/null | grep -oP '[^ ]+\.dbf$' | head -1)
if [ -n "$FEATNAMES_DBF" ]; then
    ogr2ogr -f SQLite -update -append "$TEST_DB" "/vsizip/$FEATNAMES_ZIP/$FEATNAMES_DBF" \
        -nln "tiger_featnames" \
        -skipfailures
else
    echo "ERROR: Could not find .dbf file in $FEATNAMES_ZIP"
    exit 1
fi

echo ""
echo "3. Running ETL transformations..."
(echo ".load $HELPER_LIB" && \
 cat "$BUILD_DIR/sql/setup.sql" "$BUILD_DIR/sql/convert.sql") | sqlite3 "$TEST_DB" 2>&1 | head -20

echo ""
echo "4. Verifying import results..."
echo ""
echo "Tables in database:"
sqlite3 "$TEST_DB" ".tables"

echo ""
echo "Row counts:"
sqlite3 "$TEST_DB" "SELECT 'tiger_edges' as table_name, COUNT(*) as row_count FROM tiger_edges
UNION ALL SELECT 'tiger_addr' as table_name, COUNT(*) as row_count FROM tiger_addr
UNION ALL SELECT 'tiger_featnames' as table_name, COUNT(*) as row_count FROM tiger_featnames;" 2>/dev/null

echo ""
echo "Sample tiger_edges data:"
sqlite3 "$TEST_DB" "SELECT COUNT(*) as edge_count FROM tiger_edges;"

echo ""
echo "✓ Test complete! Database: $TEST_DB"
echo ""
echo "To inspect the database manually:"
echo "  sqlite3 $TEST_DB"
echo ""
