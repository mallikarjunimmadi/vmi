import concurrent.futures
import subprocess
import csv
import time
from datetime import datetime
import platform
import logging
import os
import sys

# Function to check if the ping was successful based on return code
def is_ping_successful(returncode):
    return returncode == 0  # Return code 0 means success in most cases

# Function to ping a single server
def ping_server(server):
    # Detect the operating system
    param = '-n' if platform.system().lower() == 'windows' else '-c'
    
    try:
        # Run the ping command without capturing the output
        with open(os.devnull, 'w') as devnull:
            result = subprocess.run(['ping', param, '1', server], stdout=devnull, stderr=devnull, timeout=10)
        
        # Check if the ping command was successful using return code
        if is_ping_successful(result.returncode):
            status = 'Success'
        else:
            status = 'Failed'
        
        # Print status to the terminal
        print(f"Server: {server}, Status: {status}")
        
        # Log status to the log file
        logging.info(f"Server: {server}, Status: {status}")
        
        return (server, status)
    
    except subprocess.TimeoutExpired:
        # Print timeout status to the terminal
        print(f"Server: {server}, Status: Timeout")
        
        # Log timeout to the log file
        logging.warning(f"Server: {server}, Status: Timeout")
        
        return (server, 'Timeout')
    
    except Exception as e:
        # Print error status to the terminal
        print(f"Server: {server}, Status: Error: {e}")
        
        # Log error details to the log file
        logging.error(f"Server: {server}, Status: Error: {e}")
        
        return (server, f'Error: {e}')

# Function to run pinging in parallel
def ping_servers_concurrently(servers, max_workers=200):  # Reduce max_workers for resource safety
    report = []
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            results = list(executor.map(ping_server, servers))
            for result in results:
                report.append(result)
    except Exception as e:
        logging.error(f"Error during concurrent execution: {e}")
        sys.exit(1)  # Exit with error status if there's a critical failure
    return report

# Function to write the report to a CSV file
def write_report_to_csv(report, output_file):
    try:
        with open(output_file, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(['Server', 'Status'])
            writer.writerows(report)
    except Exception as e:
        logging.error(f"Error writing to CSV file: {e}")

# Function to read server IPs from a CSV file
def read_servers_from_csv(input_file):
    servers = []
    try:
        with open(input_file, mode='r') as file:
            reader = csv.reader(file)
            next(reader)  # Skip the header row if there is one
            for row in reader:
                if row:  # Ensure the row is not empty
                    servers.append(row[0])  # Assuming the server IP is in the first column
    except Exception as e:
        logging.error(f"Error reading server IPs from CSV file: {e}")
    return servers

if __name__ == "__main__":
    start_time = time.time()

    # Generate a timestamp for the log and report files
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # Setup logging to log to a timestamped file
    log_file = f'ping_results_{timestamp}.log'
    logging.basicConfig(filename=log_file, level=logging.INFO,
                        format='%(asctime)s - %(levelname)s - %(message)s')

    # Specify the path to the CSV file containing server IPs
    input_file = 'server_list.csv'  # Replace with the actual file path
        
    # Read the list of servers from the CSV file
    server_list = read_servers_from_csv(input_file)
    
    # Ping the servers and get the report
    report = ping_servers_concurrently(server_list)
    
    # Generate the report filename with timestamp
    output_file = f'ping_report_{timestamp}.csv'
    
    # Write the report to a CSV file
    write_report_to_csv(report, output_file)

    # Print execution time
    end_time = time.time()
    print(f"Execution completed in {end_time - start_time:.2f} seconds. Report saved to {output_file}")
    logging.info(f"Execution completed in {end_time - start_time:.2f} seconds. Report saved to {output_file}")
    
    # Ensure logs are flushed properly before script ends
    logging.shutdown()



'''
########## server_list.csv content format ##########
Hostname
10.10.69.161
10.20.128.112
10.30.14.197
10.30.14.209
10.30.14.250
'''
