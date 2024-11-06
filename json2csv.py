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

        # Open the CSV file and create a writer
        with open(csv_file, 'w', newline='') as file:
            writer = csv.writer(file)

            # Check if data is a list of dictionaries or a single dictionary
            if isinstance(data, list) and data:
                # Write header and rows if data is a list of dictionaries
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
    
    except json.JSONDecodeError:
        print("Error: The JSON file contains invalid JSON data.")
    except FileNotFoundError:
        print(f"Error: The file '{json_file}' was not found.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# Run the function
json_to_csv()
