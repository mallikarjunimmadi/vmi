Enter certificate path (certificate.cer): nbupaymentsvendorcerts.com.chained.pem
[LOG] Reading certificate from: nbupaymentsvendorcerts.com.chained.pem
[LOG] Certificate is in PEM format. Proceeding with extraction.
[LOG] Certificate 2:
[LOG] Serial Number: 166895367321599166093099326425508225765
[LOG] Issuer: CN=WR4,O=Google Trust Services,C=US
[LOG] Subject: CN=20241027.nbupaymentsvendorcerts.com
[LOG] Validity:
c:\Users\vmw347138.CORP\OneDrive - \Data-CRITICAL\Scripts\getCertificateInfo.py:17: CryptographyDeprecationWarning: Properties that return a naïve datetime object have been deprecated. Please switch to not_valid_before_utc.
  logging.info(f"  Not Before: {cert.not_valid_before}")
[LOG]   Not Before: 2024-10-27 07:03:23
c:\Users\vmw347138.CORP\OneDrive - \Data-CRITICAL\Scripts\getCertificateInfo.py:18: CryptographyDeprecationWarning: Properties that return a naïve datetime object have been deprecated. Please switch to not_valid_after_utc.
  logging.info(f"  Not After: {cert.not_valid_after}")
[LOG]   Not After: 2025-01-25 07:03:22


[LOG] Certificate 3:
[LOG] Serial Number: 170058222451459992654840509345887097805
[LOG] Issuer: CN=GTS Root R1,O=Google Trust Services LLC,C=US
[LOG] Subject: CN=WR4,O=Google Trust Services,C=US
[LOG] Validity:
[LOG]   Not Before: 2023-12-13 09:00:00
[LOG]   Not After: 2029-02-20 14:00:00


[LOG] Certificate 4:
[LOG] Serial Number: 159159747900478145820483398898491642637
[LOG] Issuer: CN=GlobalSign Root CA,OU=Root CA,O=GlobalSign nv-sa,C=BE
[LOG] Subject: CN=GTS Root R1,O=Google Trust Services LLC,C=US
[LOG] Validity:
[LOG]   Not Before: 2020-06-19 00:00:42
[LOG]   Not After: 2028-01-28 00:00:42

from cryptography import x509
from cryptography.hazmat.backends import default_backend
import sys
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='[LOG] %(message)s')

# Get certificate path from the user
cert_path = input("Enter certificate path (certificate.cer): ")

def print_cert_info(cert):
    logging.info(f"Serial Number: {cert.serial_number}")
    logging.info(f"Issuer: {cert.issuer.rfc4514_string()}")
    logging.info(f"Subject: {cert.subject.rfc4514_string()}")
    logging.info("Validity:")
    logging.info(f"  Not Before: {cert.not_valid_before}")
    logging.info(f"  Not After: {cert.not_valid_after}")
    print("\n")

try:
    logging.info(f"Reading certificate from: {cert_path}")
    with open(cert_path, "rb") as f:
        data = f.read()
        
        # Check if the certificate is in PEM format
        if b"-----BEGIN CERTIFICATE-----" in data:
            logging.info("Certificate is in PEM format. Proceeding with extraction.")
            certs = data.split(b"-----BEGIN CERTIFICATE-----")
            for idx, cert_data in enumerate(certs):
                if not cert_data.strip():
                    continue
                cert_data = b"-----BEGIN CERTIFICATE-----" + cert_data
                cert = x509.load_pem_x509_certificate(cert_data, default_backend())
                logging.info(f"Certificate {idx + 1}:")
                print_cert_info(cert)
        else:
            logging.info("Certificate is not in PEM format. Checking if it's in DER format.")
            try:
                cert = x509.load_der_x509_certificate(data, default_backend())
                logging.info("Certificate is in DER format. Proceeding with extraction.")
                print_cert_info(cert)
            except ValueError:
                logging.error("The certificate format is not recognized or invalid. Exiting.")
                sys.exit(1)

except FileNotFoundError:
    logging.error(f"File {cert_path} not found.")
except Exception as e:
    logging.error(f"An error occurred: {e}")
