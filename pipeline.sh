#!/usr/bin/env bash
#
# pipeline.sh — Download a year of NOAA Storm Events, convert to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2024
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5)
#
# This is a starter scaffold. Read the comments. Replace the [TODO] markers
# with the actual logic. Do not change the structure unless you have a reason.

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

# Year to pull. Override by passing as the first argument.
YEAR="${1:-2024}"

# NOAA currently publishes Storm Events as monthly CSV files by year.
BASE_URL="https://www.ncei.noaa.gov/data/storm-events/access/original/${YEAR}"

RAW_DIR="data/raw/${YEAR}"
PROCESSED_DIR="data/processed"

# Local combined CSV made from all monthly NOAA detail files.
COMBINED_CSV="${RAW_DIR}/storms_${YEAR}_details.csv"

# Final analysis-ready output.
OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}.parquet"

# -----------------------------------------------------------------------------
# Step 1: Set up directories
# -----------------------------------------------------------------------------

echo "[1/4] Setting up directories"
# Use mkdir -p to create RAW_DIR and PROCESSED_DIR. Both should be
# safe to call even if the directories already exist.
mkdir -p "$RAW_DIR" "$PROCESSED_DIR"

# -----------------------------------------------------------------------------
# Step 2: Download the raw file
# -----------------------------------------------------------------------------

echo "[2/4] Downloading monthly Storm Events files"
# [TODO] Use curl to download URL into RAW_GZ. Suggested flags:
#   -L       follow redirects
#   -o       write to a specific output file path
#   --fail   exit non-zero on HTTP errors (4xx/5xx)
#
# Skip the download if the file already exists (idempotency).

curl -L --fail "$BASE_URL/" \
  | grep -o 'StormEvents_details_[^"]*\.csv' \
  | sort -u \
  | while read -r FILE_NAME; do
      OUT_FILE="${RAW_DIR}/${FILE_NAME}"

      if [ -f "$OUT_FILE" ]; then
        echo "  Skipping existing file: $FILE_NAME"
      else
        echo "  Downloading: $FILE_NAME"
        curl -L --fail -o "$OUT_FILE" "${BASE_URL}/${FILE_NAME}"
      fi
    done

# -----------------------------------------------------------------------------
# Step 3: Combine monthly csv files into one
# -----------------------------------------------------------------------------
echo "[3/4] Combining monthly CSVs"

# Skip if the combined file already exists.
if [ -f "$COMBINED_CSV" ]; then
    echo "  Combined CSV already exists: $COMBINED_CSV"
else
    FIRST_FILE=$(ls "$RAW_DIR"/StormEvents_details_*.csv | head -n 1)

    # Write header from first file.
    head -n 1 "$FIRST_FILE" > "$COMBINED_CSV"

    # Append data rows from every monthly file.
    for FILE in "$RAW_DIR"/StormEvents_details_*.csv; do
        echo "  Adding $(basename "$FILE")"
        tail -n +2 "$FILE" >> "$COMBINED_CSV"
    done

    echo "  Created: $COMBINED_CSV"
fi


echo "[3/4] Combining monthly CSV files"
# [TODO] Use cat to combine all CSV files in RAW_DIR into COMBINED_CSV.
# The -k flag keeps the original .gz so the pipeline can rerun.
# Skip this step if COMBINED_CSV already exists.

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet
# -----------------------------------------------------------------------------

echo "[4/4] Converting to GeoParquet"
# [TODO] Use ogr2ogr to convert COMBINED_CSV into a GeoParquet file at OUT_PARQUET.
#
# The CSV uses BEGIN_LON / BEGIN_LAT for the storm start point. ogr2ogr can
# pick those up if you tell it the column names with -oo:
#
#   -oo X_POSSIBLE_NAMES=BEGIN_LON
#   -oo Y_POSSIBLE_NAMES=BEGIN_LAT
#
# The data is in WGS 84 (EPSG:4326). Set that explicitly with -a_srs.
#
# Use -f Parquet for the output format.
#
# Tip: ask your AI pair (see R1.3 prompts 4 and 6) for the exact ogr2ogr
# command, then verify the flags against `ogr2ogr --help` before running.

echo "Done. Output: ${OUT_PARQUET}"
echo "Open it in DuckDB:"
echo "  duckdb -c \"INSTALL spatial; LOAD spatial; SELECT COUNT(*) FROM read_parquet('${OUT_PARQUET}');\""
