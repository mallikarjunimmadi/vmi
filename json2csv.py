import json
import csv
import os

def json_to_csv():
    # Take JSON file path as input from the user
    json_file = input("Enter the path to the JSON file: ")

    # Generate the output CSV file path with the same base name
    csv_file = os.path.splitext(json_file)[0] + '.csv'

    try:
        # Check if the file is empty
        if os.path.getsize(json_file) == 0:
            print("Error: The JSON file is empty.")
            return

        # Open the JSON file and load the data
        with open(json_file, 'r') as file:
            data = json.load(file)

        # Extract the 'results' part of the JSON
        if 'results' not in data:
            print("Error: 'results' key not found in the JSON data.")
            return

        results = data['results']

        # Check if 'results' is a list of dictionaries
        if not isinstance(results, list):
            print("Error: 'results' should be a list of dictionaries.")
            return

        # Open the CSV file and create a writer
        with open(csv_file, 'w', newline='') as file:
            writer = csv.writer(file)

            # Write header and rows for the 'results' data
            if results:
                writer.writerow(results[0].keys())  # Write headers from the first dictionary
                for item in results:
                    writer.writerow(item.values())  # Write each row from 'results'
            else:
                print("The 'results' list is empty. No data to write.")

        print(f"Data from 'results' has been written to {csv_file}.")

    except json.JSONDecodeError:
        print("Error: The JSON file contains invalid JSON data.")
    except FileNotFoundError:
        print(f"Error: The file '{json_file}' was not found.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# Run the function
json_to_csv()
