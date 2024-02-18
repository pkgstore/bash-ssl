#!/usr/bin/bash -e
#
# Generating OpenSSL CA.
#
# @package    Bash
# @author     Kai Kimera <mail@kai.kim>
# @copyright  2024 iHub TO
# @license    MIT
# @version    0.0.1
# @link       https://lib.onl
# -------------------------------------------------------------------------------------------------------------------- #

(( EUID == 0 )) && { echo >&2 'This script should not be run as root!'; exit 1; }

CA_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P )"
cat="$( command -v cat )"
cp="$( command -v cp )"
mkdir="$( command -v mkdir )"
ossl="$( command -v openssl )"
sed="$( command -v sed )"
touch="$( command -v touch )"

# -------------------------------------------------------------------------------------------------------------------- #
# INITIALIZING CA-ROOT.
# -------------------------------------------------------------------------------------------------------------------- #

init_ca_root() {
  # Generating a configuration file.
  ${cat} > "${CA_DIR}/ca.root.ini" <<EOF
[ ca ]
default_ca                      = CA_default

[ CA_default ]
# Directory and file locations.
dir                             = ${CA_DIR}/ca.root
certs                           = \$dir/certs
crl_dir                         = \$dir/crl
new_certs_dir                   = \$dir/certs.new
database                        = \$dir/index.txt
serial                          = \$dir/serial
RANDFILE                        = \$dir/private/.rand

# The root key and root certificate.
private_key                     = \$dir/private/ca.root.key
certificate                     = \$dir/certs/ca.root.crt

# For certificate revocation lists.
crlnumber                       = \$dir/crlnumber
crl                             = \$dir/ca.root.crl
crl_extensions                  = crl_ext
default_crl_days                = 3650

# SHA-1 is deprecated, so use SHA-2 or SHA-3 instead.
default_md                      = sha384

name_opt                        = ca_default
cert_opt                        = ca_default
default_days                    = 3650
preserve                        = no
policy                          = policy_match

[ policy_match ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of \`man ca\`.
countryName                     = match
stateOrProvinceName             = match
organizationName                = match
organizationalUnitName          = optional
commonName                      = supplied
emailAddress                    = optional

[ policy_anything ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the \`ca\` man page.
countryName                     = optional
stateOrProvinceName             = optional
localityName                    = optional
organizationName                = optional
organizationalUnitName          = optional
commonName                      = supplied
emailAddress                    = optional

[ req ]
# Options for the \`req\` tool (\`man req\`).
default_bits                    = 4096
distinguished_name              = req_distinguished_name
string_mask                     = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md                      = sha384

# Extension to add when the -x509 option is used.
x509_extensions                 = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name (full name)
localityName                    = Locality Name (eg, city)
0.organizationName              = Organization Name (eg, company)
organizationalUnitName          = Organizational Unit Name (eg, section)
commonName                      = Common Name (e.g. server FQDN or YOUR name)
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = RU
stateOrProvinceName_default     = Moscow
localityName_default            = Moscow
0.organizationName_default      = iHUB Inc.
organizationalUnitName_default  = iHUB Root CA
emailAddress_default            = mail@ihub.to

[ v3_ca ]
# Extensions for a typical CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true
keyUsage                        = critical, digitalSignature, cRLSign, keyCertSign

[ v3_int_ca ]
# Extensions for a typical intermediate CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true, pathlen:0
keyUsage                        = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
nsCertType                      = client, email
nsComment                       = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer
keyUsage                        = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage                = clientAuth, emailProtection
# authorityInfoAccess           = OCSP;URI:http://ocsp.example.com

[ srv_cert ]
# Extensions for server certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
nsCertType                      = server
nsComment                       = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
keyUsage                        = critical, digitalSignature, keyEncipherment
extendedKeyUsage                = serverAuth
# authorityInfoAccess           = OCSP;URI:http://ocsp.example.com

[ crl_ext ]
# Extension for CRLs (\`man x509v3_config\`).
authorityKeyIdentifier          = keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (\`man ocsp\`).
basicConstraints                = CA:FALSE
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer
keyUsage                        = critical, digitalSignature
extendedKeyUsage                = critical, OCSPSigning
EOF

  # Creating a structure.
  ${mkdir} -p "${CA_DIR}"/ca.root/{certs,certs.new,crl,csr,private} \
    && ${touch} "${CA_DIR}/ca.root/index.txt" \
    && echo '1000' > "${CA_DIR}/ca.root/serial"

  # Generating a private key.
  ${ossl} ecparam -genkey -name 'secp384r1' \
    | ${ossl} ec -aes256 -out "${CA_DIR}/ca.root/private/ca.root.key"

  # Generating a public certificate.
  ${ossl} req -config "${CA_DIR}/ca.root.ini" -extensions 'v3_ca' \
    -new -x509 -days 7310 -sha384 \
    -key "${CA_DIR}/ca.root/private/ca.root.key" \
    -out "${CA_DIR}/ca.root/certs/ca.root.crt"

  # Generating public certificate info on the display.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca.root/certs/ca.root.crt"

  # Generating public certificate info to the file.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca.root/certs/ca.root.crt" \
    > "${CA_DIR}/ca.root/certs/ca.root.crt.info"
}

# -------------------------------------------------------------------------------------------------------------------- #
# INITIALIZING CA-INTERMEDIATE.
# -------------------------------------------------------------------------------------------------------------------- #

init_ca() {
  # Generating a configuration file.
  ${cp} "${CA_DIR}/ca.root.ini" "${CA_DIR}/ca.ini"
  ${sed} -i '' 's/ca.root/ca/g' "${CA_DIR}/ca.ini"
  ${sed} -i '' 's/Root CA/Intermediate CA/g' "${CA_DIR}/ca.ini"

  # Creating a structure.
  ${mkdir} -p "${CA_DIR}"/ca/{certs,certs.new,crl,csr,private} \
    && ${touch} "${CA_DIR}/ca/index.txt" \
    && echo '1000' > "${CA_DIR}/ca/serial"

  # Generating a private key.
  ${ossl} ecparam -genkey -name 'secp384r1' \
    | ${ossl} ec -aes256 -out "${CA_DIR}/ca/private/ca.key"

  # Generating a Certificate Signing Request (CSR).
  ${ossl} req -config "${CA_DIR}/ca.ini" \
    -new \
    -key "${CA_DIR}/ca/private/ca.key" \
    -out "${CA_DIR}/ca/csr/ca.csr"

  # Generating a public certificate.
  ${ossl} ca -config "${CA_DIR}/ca.root.ini" -extensions 'v3_int_ca' \
    -days 3650 -notext -md 'sha384' \
    -in "${CA_DIR}/ca/csr/ca.csr" \
    -out "${CA_DIR}/ca/certs/ca.crt"

  # Generating public certificate info on the display.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca/certs/ca.crt"

  # Generating public certificate info to the file.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca/certs/ca.crt" \
    > "${CA_DIR}/ca/certs/ca.crt.info"

  # Verifying the public certificate on the display.
  ${ossl} verify \
    -CAfile "${CA_DIR}/ca.root/certs/ca.root.crt" \
    "${CA_DIR}/ca/certs/ca.crt"

  # Generating a public certificate chain file.
  ${cat} "${CA_DIR}/ca/certs/ca.crt" "${CA_DIR}/ca.root/certs/ca.root.crt" \
    > "${CA_DIR}/ca/certs/ca.crt.chain"
}

# -------------------------------------------------------------------------------------------------------------------- #
# GENERATING A SERVER CERTIFICATE.
# -------------------------------------------------------------------------------------------------------------------- #

gen_crt_srv() {
  name="${1}"
  days="${2:-740}"

  # Generating a private key.
  ${ossl} ecparam -genkey -name 'secp384r1' \
    | ${ossl} ec -out "${CA_DIR}/ca/private/${name}.key"

  # Generating a Certificate Signing Request (CSR).
  ${ossl} req -config "${CA_DIR}/ca.ini" \
    -new \
    -key "${CA_DIR}/ca/private/${name}.key" \
    -out "${CA_DIR}/ca/csr/${name}.csr"

  # Generating a public certificate.
  ${ossl} ca -config "${CA_DIR}/ca.ini" -extensions 'srv_cert' \
    -days "${days}" -notext \
    -in "${CA_DIR}/ca/csr/${name}.csr" \
    -out "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info on the display.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info to the file.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca/certs/${name}.crt" \
    > "${CA_DIR}/ca/certs/${name}.crt.info"

  # Verifying the public certificate on the display.
  ${ossl} verify \
    -CAfile "${CA_DIR}/ca/certs/ca.crt.chain" \
    "${CA_DIR}/ca/certs/${name}.crt"
}

# -------------------------------------------------------------------------------------------------------------------- #
# GENERATING A USER CERTIFICATE.
# -------------------------------------------------------------------------------------------------------------------- #

gen_crt_usr() {
  name="${1}"
  days="${2:-740}"

  # Generating a private key.
  ${ossl} ecparam -genkey -name 'secp384r1' \
    | ${ossl} ec -out "${CA_DIR}/ca/private/${name}.key"

  # Generating a Certificate Signing Request (CSR).
  ${ossl} req -config "${CA_DIR}/ca.ini" \
    -new \
    -key "${CA_DIR}/ca/private/${name}.key" \
    -out "${CA_DIR}/ca/csr/${name}.csr"

  # Generating a public certificate.
  ${ossl} ca -config "${CA_DIR}/ca.ini" -extensions 'usr_cert' \
    -days "${days}" -notext \
    -in "${CA_DIR}/ca/csr/${name}.csr" \
    -out "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info on the display.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info to the file.
  ${ossl} x509 -noout -text \
    -in "${CA_DIR}/ca/certs/${name}.crt" \
    > "${CA_DIR}/ca/certs/${name}.crt.info"

  # Verifying the public certificate on the display.
  ${ossl} verify \
    -CAfile "${CA_DIR}/ca/certs/ca.crt.chain" \
    "${CA_DIR}/ca/certs/${name}.crt"
}

# -------------------------------------------------------------------------------------------------------------------- #
# SIGNING THE SERVER CERTIFICATE.
# -------------------------------------------------------------------------------------------------------------------- #

sig_crt_srv(){
  name="${1}"
  days="${2:-740}"

  # Generating a public certificate.
  ${ossl} ca -config "${CA_DIR}/ca.ini" -extensions 'srv_cert' \
    -days "${days}" -notext \
    -in "${name}" \
    -out "${CA_DIR}/ca/certs/${name}.crt"
}

# -------------------------------------------------------------------------------------------------------------------- #
# SIGNING THE USER CERTIFICATE.
# -------------------------------------------------------------------------------------------------------------------- #

sig_crt_usr(){
  name="${1}"
  days="${2:-740}"

  # Generating a public certificate.
  ${ossl} ca -config "${CA_DIR}/ca.ini" -extensions 'usr_cert' \
    -days "${days}" -notext \
    -in "${name}" \
    -out "${CA_DIR}/ca/certs/${name}.crt"
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< RUNNING SCRIPT >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

"$@"
