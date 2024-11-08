from cryptography import x509
from cryptography.hazmat.backends import default_backend
import sys
import logging
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(message)s')

# Get certificate path from the user
cert_path = input("Enter certificate path (certificate.cer): ")

def print_cert_info(cert, idx):
    # Calculate the thumbprint (SHA1 fingerprint)
    sha1_digest = hashes.Hash(hashes.SHA1(), backend=default_backend())
    sha1_digest.update(cert.public_bytes(encoding=serialization.Encoding.DER))
    thumbprint_sha1 = sha1_digest.finalize().hex().upper()

    # Calculate the thumbprint (SHA256 fingerprint)
    sha256_digest = hashes.Hash(hashes.SHA256(), backend=default_backend())
    sha256_digest.update(cert.public_bytes(encoding=serialization.Encoding.DER))
    thumbprint_sha256 = sha256_digest.finalize().hex().upper()

    logging.info(f"Certificate {idx}:")
    logging.info(f"  Serial Number: {cert.serial_number}")
    logging.info(f"  Subject: {cert.subject.rfc4514_string()}")
    logging.info(f"  Issuer: {cert.issuer.rfc4514_string()}")
    logging.info("  Validity:")
    logging.info(f"    Not Before: {cert.not_valid_before_utc}")
    logging.info(f"    Not After: {cert.not_valid_after_utc}")
    logging.info(f"  Thumbprint (SHA1): {thumbprint_sha1}")
    logging.info(f"  Thumbprint (SHA256): {thumbprint_sha256}")
    print("\n")

try:
    logging.info(f"Reading certificate from: {cert_path}")
    with open(cert_path, "rb") as f:
        data = f.read()
        
        # Check if the certificate is in PEM format
        if b"-----BEGIN CERTIFICATE-----" in data:
            logging.info("Certificate is in PEM format. Proceeding with extraction.")
            certs = data.split(b"-----BEGIN CERTIFICATE-----")
            for idx, cert_data in enumerate(certs, start=0):
                if not cert_data.strip():
                    continue
                cert_data = b"-----BEGIN CERTIFICATE-----" + cert_data
                cert = x509.load_pem_x509_certificate(cert_data, default_backend())
                print_cert_info(cert, idx)
        else:
            logging.info("Certificate is not in PEM format. Checking if it's in DER format.")
            try:
                cert = x509.load_der_x509_certificate(data, default_backend())
                logging.info("Certificate is in DER format. Proceeding with extraction.")
                print_cert_info(cert, 1)
            except ValueError:
                logging.error("The certificate format is not recognized or invalid. Exiting.")
                sys.exit(1)

except FileNotFoundError:
    logging.error(f"File {cert_path} not found.")
except Exception as e:
    logging.error(f"An error occurred: {e}")
