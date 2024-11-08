[LOG] Reading certificate from: sbi.nbupaymentsvendorcerts.com.chained.pem
[LOG] Certificate is in PEM format. Proceeding with extraction.
1923
1809
1927
[LOG] Processing cert_00.pem
        Serial Number:
            7d:8e:e0:e8:ae:1e:f4:ba:12:c3:b9:f8:1f:4e:22:e5
        Issuer: C = US, O = Google Trust Services, CN = WR4
        Validity
            Not Before: Oct 27 07:03:23 2024 GMT
            Not After : Jan 25 07:03:22 2025 GMT
        Subject: CN = sbi20241027.nbupaymentsvendorcerts.com
                06:59:A8:18:51:39:EF:D6:88:05:D9:99:CE:AF:1B:F6:1C:AA:8D:3C

[LOG] Processing cert_01.pem
        Serial Number:
            7f:f0:05:b4:da:75:b8:6a:5a:c6:1f:e4:30:77:13:cd
        Issuer: C = US, O = Google Trust Services LLC, CN = GTS Root R1
        Validity
            Not Before: Dec 13 09:00:00 2023 GMT
            Not After : Feb 20 14:00:00 2029 GMT
        Subject: C = US, O = Google Trust Services, CN = WR4
                9B:C8:11:BC:3D:AA:36:B9:31:8C:4E:8F:44:D5:57:32:2F:C3:C0:61
                Full Name:

[LOG] Processing cert_02.pem
        Serial Number:
            77:bd:0d:6c:db:36:f9:1a:ea:21:0f:c4:f0:58:d3:0d
        Issuer: C = BE, O = GlobalSign nv-sa, OU = Root CA, CN = GlobalSign Root CA
        Validity
            Not Before: Jun 19 00:00:42 2020 GMT
            Not After : Jan 28 00:00:42 2028 GMT
        Subject: C = US, O = Google Trust Services LLC, CN = GTS Root R1
                E4:AF:2B:26:71:1A:2B:48:27:85:2F:52:66:2C:EF:F0:89:13:71:3E
                Full Name:


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

# Check if the certificate is in PEM format using awk
if awk '/-----BEGIN CERTIFICATE-----/ {found=1; exit} END {exit !found}' "$cpath"; then
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
