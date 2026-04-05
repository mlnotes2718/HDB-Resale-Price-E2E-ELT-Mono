import json
import requests
import time
import pandas as pd
import logging

# code supplied by data.gov.sg to download the dataset
# Function to download the dataset

def download_file(DATASET_ID):
  # initiate download
  s = requests.Session()
  initiate_download_response = s.get(
      f"https://api-open.data.gov.sg/v1/public/api/datasets/{DATASET_ID}/initiate-download",
      headers={"Content-Type":"application/json"},
      json={}
  )

  # poll download
  MAX_POLLS = 5
  for i in range(MAX_POLLS):
    poll_download_response = s.get(
        f"https://api-open.data.gov.sg/v1/public/api/datasets/{DATASET_ID}/poll-download",
        headers={"Content-Type":"application/json"},
        json={}
    )
    logging.info("Poll download response:", poll_download_response.json())

    # The 'or {}' handles the case where .get() returns None
    response_data = poll_download_response.json().get('data') or {}
    if "url" in response_data:
      DOWNLOAD_URL = response_data['url']
      df = pd.read_csv(DOWNLOAD_URL)

      # check if the dataframe is empty
      if df.empty:
        logging.info("The downloaded dataframe is empty. Please check the dataset or try again later.")
        return None
      
      
      #display(df.head())
      # log the shape of the dataframe
      logging.info(f"Dataframe shape: {df.shape}")
      logging.info("\nDataframe loaded!")
      return df
    if i == MAX_POLLS - 1:
      logging.info(f"{i+1}/{MAX_POLLS}: No result found, possible error with dataset, please try again or let us know at https://go.gov.sg/datagov-supportform\n")
    else:
      logging.info(f"{i+1}/{MAX_POLLS}: No result yet, continuing to poll\n")
    time.sleep(3)
