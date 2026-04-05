import pandas as pd
import logging
import os

logging.basicConfig(level=logging.INFO)

def clean_hdb_resale_from_2017(source_folder, source_file_name, seed_folder, cleaned_file_name):
    
    logging.info("Cleaning HDB Resale Price File")

    # Setting source folder and path
    current_path = os.getcwd()
    hdb_resale_file = os.path.join(current_path, source_folder, source_file_name)
    
    # load csv file
    hdb_resale = pd.read_csv(hdb_resale_file)

    # Data cleaning
    hdb_resale_no_duplicates = hdb_resale.drop_duplicates(keep='first')
    
    # Setting seed path
    seed_path = os.path.join(current_path, seed_folder, cleaned_file_name)

    # Save file to seeds folder
    hdb_resale_no_duplicates.to_csv(seed_path, index = False)

    logging.info("HDB Resale File Cleaned and Saved to Seeds")