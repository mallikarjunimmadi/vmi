Enter certificate path (certificate.cer): sbi.nbupaymentsvendorcerts.com.chained.pem
[LOG] Reading certificate from: sbi.nbupaymentsvendorcerts.com.chained.pem
grep: unrecognized option '-----BEGIN CERTIFICATE-----'
Usage: grep [OPTION]... PATTERNS [FILE]...
Try 'grep --help' for more information.
[LOG] Certificate is not in PEM format. Checking if it's in DER format.
[LOG] The certificate format is not recognized or invalid. Exiting.
imallikarjun@ubuntu-01:/data$


#!/bin/bash

read -p "Enter certificate path (certificate.cer): " cpath

log() {
    echo "[LOG] $1"
}

# Check if the certificate path exists
if [ ! -f "$cpath" ]; then
    log "File $cpath not found. Exiting."
    exit 1
fi

log "Reading certificate from: $cpath"

# Check if the certificate is in PEM format
if grep -q "-----BEGIN CERTIFICATE-----" "$cpath"; then
    log "Certificate is in PEM format. Proceeding with extraction."

    # Split PEM file into individual certificates
    csplit -z -f cert_ -b "%02d.pem" "$cpath" '/-----BEGIN CERTIFICATE-----/' '{*}'

    # Process each PEM certificate
    for cert_file in cert_*.pem; do
        log "Processing $cert_file"
        openssl x509 -in "$cert_file" -text -noout | grep -A2 "Serial Number\|Issuer\|Subject\|Validity" | grep -v "Public\|Identifier\|X509v3\|--\|CA Issuers\|DNS\|Signature"
        echo ""
    done

    # Cleanup temporary certificate files
    log "Cleaning up temporary certificate files."
    rm cert_*.pem
else
    log "Certificate is not in PEM format. Checking if it's in DER format."

    # Convert DER to PEM if needed
    if file "$cpath" | grep -q "DER"; then
        log "Certificate is in DER format. Converting to PEM format."
        openssl x509 -inform der -in "$cpath" -out temp_cert.pem
        log "Processing temp_cert.pem"
        openssl x509 -in temp_cert.pem -text -noout | grep -A2 "Serial Number\|Issuer\|Subject\|Validity" | grep -v "Public\|Identifier\|X509v3\|--\|CA Issuers\|DNS\|Signature"
        echo ""
        rm temp_cert.pem
    else
        log "The certificate format is not recognized or invalid. Exiting."
        exit 1
    fi
fi

log "Processing completed."