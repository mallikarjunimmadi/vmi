import pandas as pd
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S'
)

def merge_excel_files(directory, output_file):
    # List all files in the directory, excluding the output file
    file_list = [f for f in os.listdir(directory) if f.endswith('.xlsx') and f != os.path.basename(output_file)]
   
    # Dictionary to hold DataFrames for each sheet
    merged_data = {}

    # Process each file
    for file in file_list:
        file_path = os.path.join(directory, file)
        logging.info(f"Processing file: {file}")
       
        try:
            # Read the Excel file
            excel = pd.ExcelFile(file_path, engine='openpyxl')

            # For each sheet in the file
            for sheet_name in excel.sheet_names:
                start_time = datetime.now()
                logging.info(f"  Processing sheet: {sheet_name}")

                # Read the sheet into a DataFrame
                df = pd.read_excel(file_path, sheet_name=sheet_name, engine='openpyxl')

                # Filter out empty or all-NA rows
                df = df.dropna(how='all')

                # Append or concatenate to the corresponding sheet in merged_data
                if sheet_name in merged_data:
                    merged_data[sheet_name] = pd.concat([merged_data[sheet_name], df], ignore_index=True)
                else:
                    merged_data[sheet_name] = df

                end_time = datetime.now()
                duration = (end_time - start_time).total_seconds()
                logging.info(f"  Finished processing sheet: {sheet_name} (Duration: {duration} seconds)")

        except Exception as e:
            logging.error(f"Error processing file {file}: {e}")

    # Open the Excel writer and write all collected DataFrames
    with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
        for sheet_name, df in merged_data.items():
            df.to_excel(writer, sheet_name=sheet_name, index=False)
            logging.info(f"  Writing sheet: {sheet_name} to output file")

    # Log the completion of the file writing process
    logging.info(f"Finished writing all sheets to {output_file}")

# Directory containing data files
directory = '.'

# Output file
output_file = 'merged_data.xlsx'

# Merge the files
merge_excel_files(directory, output_file)
