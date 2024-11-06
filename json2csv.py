import json
import csv

def json_to_csv():
    # Take JSON and CSV file paths as input from the user
    json_file = input("Enter the path to the JSON file: ")
    csv_file = input("Enter the path where you want to save the CSV file: ")

    # Open the JSON file and load the data
    with open(json_file, 'r') as file:
        data = json.load(file)

    # Open the CSV file and create a writer
    with open(csv_file, 'w', newline='') as file:
        # Create a CSV writer object
        writer = csv.writer(file)

        # Write the header using keys of the first dictionary in the JSON data
        writer.writerow(data[0].keys())

        # Write rows for each dictionary in the JSON data
        for item in data:
            writer.writerow(item.values())

    print(f"Data has been written to {csv_file}.")

# Run the function
json_to_csv()
