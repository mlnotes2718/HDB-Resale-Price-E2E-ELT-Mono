# HDB Resale Price End-to-End ELT v0.1.0-alpha

## Objective:
- The objective of this project is demonstrate of a simple ELT pipeline using the public dataset `HDB Resale Price` in Singapore.

## Project Architecture and Design
- EDA is done at the minimum for pipeline testing purpose.
- Architecture is borrowed from a course project https://github.com/mlnotes2718/module2-project
- We use Google Cloud Platform (GCP) Bigquery as our primary data warehouse.
- We use Python script for data extraction and use dbt seeds for data loading into data warehouse.
- dbt transformation is done at the minimum to demonstrate the pipeline.
- We use Github Secrets to stored all the credentials, local testing method is provided below.
- We use Github Action to run this project.
## Pipeline Architecture Diagram

```
data.gov.sg
   (HDB Resale Dataset)
        |
        v
   data_download.py (Extract)
        |
        v
   data/hdb_resale_price.csv (Raw CSV)
        |
        v
   clean_hdb_resale_from_2017.py (Clean)
        |
        v
   hdb_resale_e2e/seeds/clean_hdb_resale_file.csv (Cleaned CSV)
        |
        v
   dbt seed --> BigQuery Raw Dataset (Load)
        |
        v
   dbt run --> Staging Layer: stg_resale_transactions (Transform)
        |
        v
   dbt run --> Mart Layer: Facts & Dimensions (Transform)
        |
        v
   dbt test --> Validation & Quality Checks (Test)
```
## Installation and Setup

### 0. Folder Structure

```
HDB-Resale-Price-E2E-ELT/
├── README.md
├── main.py                          # Main entry point for data extraction process
├── requirements.txt                 # Python dependencies
├── environment.yml                  # Conda environment file
├── run.sh                           # Bash script to run full ELT pipeline and main entry point
├── eda.ipynb                        # Exploratory data analysis notebook
│
├── data/                           # Raw data directory
│   └── hdb_resale_price.csv        # Downloaded raw dataset
│
├── src/                            # Python source code
│   ├── config.yaml                 # Configuration file
│   ├── data_download.py            # Download data from data.gov.sg
│   └── clean_hdb_resale_from_2017.py  # Data cleaning logic
│
├── hdb_resale_e2e/                # dbt project
│   ├── dbt_project.yml             # dbt project configuration
│   ├── profiles.yml                # dbt BigQuery connection (EDIT THIS)
│   ├── packages.yml                # dbt package dependencies
│   │
│   ├── seeds/                      # dbt seed data
│   │   └── clean_hdb_resale_file.csv
│   │
│   ├── models/                     # dbt transformation models
│   │   ├── schema.yml
│   │   ├── staging/
│   │   │   └── stg_resale_transactions.sql
│   │   └── marts/
│   │       ├── fact_resale_transactions.sql
│   │       ├── aggregate/
│   │       │   └── monthly_resale_summary.sql
│   │       └── dimensions/
│   │           ├── dim_date.sql
│   │           ├── dim_location.sql
│   │           └── dim_property.sql
│   │
│   ├── macros/                     # dbt macros
│   │   └── positive_values.sql
│   │
│   ├── tests/                      # dbt tests
│   │
│   ├── analyses/                   # dbt analyses
│   │   └── debug_duplicates.sql
│   │
│   └── snapshots/
│
├── assets/
│
└── .github/                        # GitHub Actions
    └── workflows/
        └── github-actions.yml      # CI/CD workflow

```

### 1. Set up the Python environment

This repository uses Python and DBT. Create the environment with Conda:

```bash
conda env create -f environment.yml
conda activate hdb-elt
```

Alternatively, install the Python dependencies directly:

```bash
pip install -r requirements.txt
```

### 2. Review configuration

The package reads runtime settings from `src/config.yaml`.

Key values include:

- `DATASET_ID`: data.gov.sg dataset identifier
- `source_folder`: local folder where the downloaded CSV is saved (`data`)
- `hdb_resale_file_name`: downloaded file name
- `seed_folder_path`: path to the DBT seed folder (`./hdb_resale_e2e/seeds/`)
- `cleaned_hdb_resale_file_name`: cleaned CSV output name saved to the DBT seed folder

### 3. Review dbt Configuration

The dbt project is configured in `hdb_resale_e2e/profiles.yml`. You **must** update the GCP project ID to match your own project.

#### Update GCP Project ID

Open `hdb_resale_e2e/profiles.yml` and replace the `project` value in all three environments (`dev`, `prod`, `raw`) with your GCP project ID:

```yaml
hdb_resale_e2e:
  outputs:
    prod:
      project: YOUR-GCP-PROJECT-ID  # Change this
      dataset: hdb_resale_prod      # Optional: customize dataset name
      ...
    dev:
      project: YOUR-GCP-PROJECT-ID  # Change this
      dataset: hdb_resale_dev       # Optional: customize dataset name
      ...
    raw:
      project: YOUR-GCP-PROJECT-ID  # Change this
      dataset: hdb_resale_raw       # Optional: customize dataset name
      ...
```

**Important**: The GCP project ID **must** be updated to your own project ID. This is required for dbt to connect to your BigQuery instance.

#### Environments

- **raw**: loaded with dbt seed (initial data load from the cleaned CSV)
- **dev**: used for development and testing transformations
- **prod**: used for production transformations

You can customize the dataset names if desired, or use the defaults provided. The default target is `dev` (see `target: dev` at the end of the file).


### 4. Configure GCP and email secrets

This repo uses GitHub Actions secrets for BigQuery and email notifications.

#### GCP service account key

- Create a Google Cloud project under `No Organization`.
- Enable the BigQuery API for that project.
- Create a service account and give it the required BigQuery permissions.
- Download the service account key as JSON.
- Use the JSON contents as the value for `DBT_BIGQUERY_SERVICE_ACCOUNT_KEY`.

> Important: the GCP project must be under `No Organization`.

#### Email notification secrets

- `MAIL_USERNAME`: your Gmail address.
- `MAIL_PASSWORD`: a Gmail app password, not your regular Gmail password.
- `COLLABORATORS_EMAILS`: at least one email address to receive workflow notifications.

> Important: `MAIL_PASSWORD` must be a Gmail app password if you are using Gmail SMTP.

Please refer to [docs/github_secrets.md](docs/github_secrets.md) for details of setting up github secrets.

## Running Project
### 1. Run the pipeline

To run only the Python download and cleaning steps:

```bash
python main.py
```

To run the full ELT process including DBT transformation and tests:

```bash
bash run.sh
```

### 2. Test locally with secrets

First create and activate the Conda environment:

```bash
conda env create -f environment.yml
conda activate hdb-elt
```

Then export the required secret values and run the pipeline:

```bash
export DBT_BIGQUERY_SERVICE_ACCOUNT_KEY="$(cat /path/to/bq-key.json)"
export MAIL_USERNAME="..."
export MAIL_PASSWORD="..."
export COLLABORATORS_EMAILS="you@example.com"

./run.sh
```

### 3. What happens when you run it

- `main.py` downloads the HDB resale dataset from data.gov.sg using `src/data_download.py`
- the raw CSV is saved to `data/hdb_resale_price.csv`
- `src/clean_hdb_resale_from_2017.py` cleans duplicates and writes a seed CSV to `hdb_resale_e2e/seeds/`
- `run.sh` then runs DBT commands inside the `hdb_resale_e2e` project:
  - `dbt clean`
  - `dbt deps`
  - `dbt seed --target raw`
  - `dbt run`
  - `dbt test`

### 8. Notes

- Ensure DBT is installed and configured for your target environment.
- If `run.sh` is not executable, use `bash run.sh`.
- Update `src/config.yaml` to change dataset IDs, file names, or folder paths.
