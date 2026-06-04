# NOAA Storms Pipeline

A Bash pipeline that downloads NOAA Storm Events data, combines monthly files into annual datasets, and creates a GeoParquet file that can be opened directly in QGIS or queried with DuckDB.

## What it does

`pipeline.sh` takes a year (default: 2024), downloads the NOAA Storm Events **details** and **locations** files for each month, combines them into annual datasets, and converts the locations data into a GeoParquet file at:

```text
data/processed/storms_{YEAR}.parquet
```

The script is idempotent, meaning it can be run multiple times without re-downloading or rebuilding files that already exist.

## The data

* **Source:** NOAA Storm Events Database
* **License:** Public domain (US federal data)
* **What's in it:** storm event records and associated location points across the United States

NOAA currently publishes Storm Events data as monthly CSV files. During this project I discovered that the original project scaffold referenced an older NOAA download structure, so the pipeline was adapted to work with NOAA's current archive layout.

## How to run it

Requirements:

* Git Bash (or another Bash environment)
* GDAL / ogr2ogr
* curl

Clone the repository:

```bash
git clone https://github.com/{your-username}/noaa-storms-pipeline.git
cd noaa-storms-pipeline
```

Run the pipeline:

```bash
bash pipeline.sh
```

Or specify a year:

```bash
bash pipeline.sh 2023
```

The output GeoParquet file will be written to:

```text
data/processed/storms_2024.parquet
```

## Output

The resulting GeoParquet can be:

* Opened directly in QGIS
* Queried using DuckDB
* Read with GeoPandas
* Used as input to other geospatial workflows

## What I learned

I expected this project to be mostly about writing a Bash script, but a surprising amount of time was spent investigating the source data. The project instructions referenced an older NOAA download structure that no longer matched the current archive, so I had to inspect NOAA's directory layout and adjust the workflow to use monthly files instead.

I also learned how useful it is to build and test a pipeline one step at a time. Creating small Git commits after each working stage made it much easier to troubleshoot problems and avoid breaking earlier work.

## Stack

* Bash
* Git
* curl
* GDAL / ogr2ogr
* GeoParquet
* QGIS
* DuckDB
