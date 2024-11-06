import csv
import ipaddress
import os
import sys

def generate_ip_list(subnet):
    try:
        network = ipaddress.ip_network(subnet)
        return [str(ip) for ip in network]
    except ValueError as e:
        print(f"Invalid subnet: {e}")
        return []

def process_csv(input_file, output_file):
    with open(input_file, mode='r') as infile, open(output_file, mode='w', newline='') as outfile:
        reader = csv.DictReader(infile)
        fieldnames = ['ip_address', 'subnet', 'subnetmask', 'gateway', 'vlan', 'vrfName', 'applicationName', 'zone', 'pod', 'rack', 'location' ]
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()

        for row in reader:
            subnet = row['subnet']
            gateway = row['gateway']
            vlan = row['vlan']
            vrfName = row['vrfName']
            applicationName = row['applicationName']
            zone = row['zone']
            subnetmask = row['subnetmask']
            pod = row['pod']
            rack = row['rack']
            location = row['location']
#            comments = row['Comments']

            ip_list = generate_ip_list(subnet)
            for ip in ip_list:
                writer.writerow({'ip_address': ip, 'subnet': subnet, 'subnetmask': subnetmask,'gateway': gateway, 'vlan': vlan, 'vrfName': vrfName, 'applicationName': applicationName, 'zone': zone, 'pod': pod, 'rack': rack, 'location': location})

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <input_csv>")
        sys.exit(1)

    input_csv = sys.argv[1]
    if not os.path.isfile(input_csv):
        print(f"File not found: {input_csv}")
        sys.exit(1)

    output_csv = os.path.join(os.getcwd(), 'sbi-IPAM.csv')
    process_csv(input_csv, output_csv)
    print(f"Output written to {output_csv}")

if __name__ == "__main__":
    main()
