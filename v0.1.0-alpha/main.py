# Standard library imports
import logging

# Third-party imports
import pandas as pd
import yaml

# Local application/library specific imports
from src.data_download import download_file
from src.clean_hdb_resale_from_2017 import clean_hdb_resale_from_2017


logging.basicConfig(level=logging.INFO)

def main():

    logging.info("Starting main.py")

    # Configuration file path
    logging.info("Loading Configurations")
    config_path = "./src/config.yaml"

    with open(config_path, "r") as file:
        config = yaml.safe_load(file)

    # Load configurations
    source_folder = config["source_folder"]
    seed_destination = config["seed_folder_path"]

    # Load Data Source from data.gov.sg
    logging.info("Loading data from data.gov.sg")
    df = download_file(config["DATASET_ID"])

    if df is not None:
        df.to_csv("./data/hdb_resale_price.csv", index=False)
    else:
        logging.error("Dataframe is None. Download may have failed.")

    # Initialize and run data preparation
    logging.info("Data Cleaning")
    
    # Cleaning HDB Resale file
    hdb_resale_file_name = config['hdb_resale_file_name']
    cleaned_hdb_resale_file_name = config['cleaned_hdb_resale_file_name'] 
    clean_hdb_resale_from_2017(source_folder, hdb_resale_file_name, seed_destination, cleaned_hdb_resale_file_name)
    logging.info("Data Cleaning Completed")

    logging.info("End of Python script.")
    logging.info("End of data download and data cleaning")


if __name__ == "__main__":
    main()
