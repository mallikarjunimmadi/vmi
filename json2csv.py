import json
import csv
import os

def json_to_csv():
    # Take JSON file path as input from the user
    json_file = input("Enter the path to the JSON file: ")

    # Generate the output CSV file path with the same base name
    csv_file = os.path.splitext(json_file)[0] + '.csv'

    # Open the JSON file and load the data
    with open(json_file, 'r') as file:
        data = json.load(file)

    # Open the CSV file and create a writer
    with open(csv_file, 'w', newline='') as file:
        writer = csv.writer(file)

        # Check if data is a list of dictionaries or a single dictionary
        if isinstance(data, list):
            # Write header and rows if data is a list of dictionaries
            if len(data) > 0:
                writer.writerow(data[0].keys())
                for item in data:
                    writer.writerow(item.values())
        elif isinstance(data, dict):
            # For a single dictionary, write keys as headers and values as a single row
            writer.writerow(data.keys())
            writer.writerow(data.values())
        else:
            print("Unexpected JSON format. Please provide a JSON file with a list of dictionaries or a single dictionary.")
            return

    print(f"Data has been written to {csv_file}.")

# Run the function
json_to_csv()
