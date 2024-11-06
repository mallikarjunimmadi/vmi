#! /bin/bash
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
echo
printf "${YELLOW}Generating Private Key"
loc=/home/imallikarjun/certs
openssl genrsa -out $loc/private-key.key 4096
echo
printf "Private Key Generated and the path to file is: "$loc/private-key.key
while IFS="," read -r rec_column1 rec_column2
do
        echo
  echo "creating folder" $rec_column1
  echo "Location: "$loc/$rec_column1
  mkdir -p $loc/$rec_column1
  echo "Copying configuration template"
  cp -p $loc/config.cnf $loc/$rec_column1/csr.cnf
  echo
  echo "Copying private key"
  cp -p $loc/private-key.key $loc/$rec_column1/private-key.key
  echo
  echo "Modifying configuration file"
  sed -i "s/homelab.local/$rec_column1/g" $loc/$rec_column1/csr.cnf
  sed -i "s/10.10.10.10/$rec_column2/g" $loc/$rec_column1/csr.cnf
  echo "Modification is completed"
  echo
  echo "Generating csr file"
#  openssl req -new -config $loc/$rec_column1/csr.cnf -sha256 -key $loc/private-key.key -out $loc/$rec_column1/$rec_column1.csr
openssl req -new -config $loc/$rec_column1/csr.cnf -sha256 -key $loc/private-key.key -out $loc/$rec_column1/$rec_column1.csr
  echo "CSR file generated and the path to csr is " $loc/$rec_column1/$rec_column1.csr
done < <(tail -n +2 $loc/hostsInfo.csv)


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
########################################### csr.cnf content ###########################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# OpenSSL configuration to generate a new key with signing requst for a x509v3
# multidomain certificate
#
# openssl req -config bla.cnf -new | tee csr.pem
# or
# openssl req -config bla.cnf -new -out csr.pem
[ req ]
default_bits       = 4096
default_md         = sha512
#default_keyfile    = key.pem
prompt             = no
encrypt_key        = no

# base request
distinguished_name = req_distinguished_name

# extensions
req_extensions     = v3_req

# distinguished_name
[ req_distinguished_name ]
countryName            = "IN"                     # C=
stateOrProvinceName    = "MH"                 # ST=
localityName           = "Navi Mumbai"                 # L=
organizationName       = "State Bank of India"        # O=
organizationalUnitName = "DC & CS"          # OU=
commonName             =             # CN=
emailAddress           = "meghdoot.support@sbi.co.in"  # CN/emailAddress=

# req_extensions
[ v3_req ]
# The subject alternative name extension allows various literal values to be
# included in the configuration file
# http://www.openssl.org/docs/apps/x509v3_config.html
subjectAltName  = DNS:,IP:
# multidomain certificate

# vim:ft=config


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
########################################### hostsList.csv content format ###########################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

HostName,IP Address
mc4b11es0035,10.10.10.100

