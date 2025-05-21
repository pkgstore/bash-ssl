#!/usr/bin/env -S bash -euo pipefail
# -------------------------------------------------------------------------------------------------------------------- #
# OPENSSL CA
# -------------------------------------------------------------------------------------------------------------------- #
# @package    Bash
# @author     Kai Kimera <mail@kai.kim>
# @license    MIT
# @version    0.1.0
# @link       https://lib.onl/ru/2023/10/6733cb51-62a0-5ed9-b421-8f08c4e0cb18/
# -------------------------------------------------------------------------------------------------------------------- #

(( EUID == 0 )) && { echo >&2 'This script should not be run as root!'; exit 1; }

# Variables.
CA_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P )"

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function _title() {
  echo '' && echo "${1}" && echo ''
}

function init_ca_root() {
  # Generating a configuration file.
  cat > "${CA_DIR}/ca.root.ini" <<EOF
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
0.organizationName_default      = LocalHost
organizationalUnitName_default  = LocalHost Root CA
emailAddress_default            = mail@localhost

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
  _title '--- [SSL-CA-ROOT] CREATING A STRUCTURE'
  mkdir -p "${CA_DIR}"/ca.root/{certs,certs.new,crl,csr,private} \
    && chmod 700 "${CA_DIR}/ca.root/private" \
    && touch "${CA_DIR}/ca.root/index.txt" \
    && echo '1000' > "${CA_DIR}/ca.root/serial"

  # Generating a private key.
  _title '--- [SSL-CA-ROOT] GENERATING A PRIVATE KEY'
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -aes256 -out "${CA_DIR}/ca.root/private/ca.root.key" \
    && chmod 400 "${CA_DIR}/ca.root/private/ca.root.key"

  # Generating a public certificate.
  _title '--- [SSL-CA-ROOT] GENERATING A PUBLIC CERTIFICATE'
  openssl req -config "${CA_DIR}/ca.root.ini" -extensions 'v3_ca' -new -x509 -days 7310 -sha384 \
    -key "${CA_DIR}/ca.root/private/ca.root.key" \
    -out "${CA_DIR}/ca.root/certs/ca.root.crt" \
    && chmod 444 "${CA_DIR}/ca.root/certs/ca.root.crt"

  # Generating public certificate info on the display.
  openssl x509 -noout -text -in "${CA_DIR}/ca.root/certs/ca.root.crt"

  # Generating public certificate info to the file.
  openssl x509 -noout -text -in "${CA_DIR}/ca.root/certs/ca.root.crt" > "${CA_DIR}/ca.root/certs/ca.root.crt.info"
}

function init_ca() {
  # Generating a configuration file.
  _title '--- [SSL-CA] GENERATING A CONFIGURATION FILE'
  cp "${CA_DIR}/ca.root.ini" "${CA_DIR}/ca.ini"
  sed -i \
    -e 's|ca.root|ca|g' \
    -e 's|Root CA|Intermediate CA|g' \
    -e 's|= policy_match|= policy_anything|g' "${CA_DIR}/ca.ini"

  # Creating a structure.
  _title '--- [SSL-CA] CREATING A STRUCTURE'
  mkdir -p "${CA_DIR}"/ca/{certs,certs.new,crl,csr,private} \
    && chmod 700 "${CA_DIR}/ca/private" \
    && touch "${CA_DIR}/ca/index.txt" \
    && echo '1000' > "${CA_DIR}/ca/serial" \
    && echo '1000' > "${CA_DIR}/ca/crlnumber"

  # Generating a private key.
  _title '--- [SSL-CA] GENERATING A PRIVATE KEY'
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -aes256 -out "${CA_DIR}/ca/private/ca.key" \
    && chmod 400 "${CA_DIR}/ca/private/ca.key"

  # Generating a Certificate Signing Request (CSR).
  _title '--- [SSL-CA] GENERATING A CERTIFICATE SIGNING REQUEST (CSR)'
  openssl req -config "${CA_DIR}/ca.ini" -new -key "${CA_DIR}/ca/private/ca.key" -out "${CA_DIR}/ca/csr/ca.csr"

  # Generating a public certificate.
  _title '--- [SSL-CA] GENERATING A PUBLIC CERTIFICATE'
  openssl ca -config "${CA_DIR}/ca.root.ini" -extensions 'v3_int_ca' -days 3650 -notext -md 'sha384' \
    -in "${CA_DIR}/ca/csr/ca.csr" \
    -out "${CA_DIR}/ca/certs/ca.crt" \
    && chmod 444 "${CA_DIR}/ca/certs/ca.crt"

  # Generating public certificate info on the display.
  openssl x509 -noout -text -in "${CA_DIR}/ca/certs/ca.crt"

  # Generating public certificate info to the file.
  openssl x509 -noout -text -in "${CA_DIR}/ca/certs/ca.crt" > "${CA_DIR}/ca/certs/ca.crt.info"

  # Verifying the public certificate on the display.
  openssl verify -CAfile "${CA_DIR}/ca.root/certs/ca.root.crt" "${CA_DIR}/ca/certs/ca.crt"

  # Generating a public certificate chain file.
  cat "${CA_DIR}/ca/certs/ca.crt" "${CA_DIR}/ca.root/certs/ca.root.crt" > "${CA_DIR}/ca/certs/ca.crt.chain" \
    && chmod 444 "${CA_DIR}/ca/certs/ca.crt.chain"
}

function gen_crt_srv() {
  local name; name="${1}"
  local days; days="${2:-740}"

  # Generating a private key.
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -out "${CA_DIR}/ca/private/${name}.key" \
    && chmod 400 "${CA_DIR}/ca/private/${name}.key"

  # Generating a Certificate Signing Request (CSR).
  openssl req -config "${CA_DIR}/ca.ini" -new \
    -key "${CA_DIR}/ca/private/${name}.key" \
    -out "${CA_DIR}/ca/csr/${name}.csr"

  # Generating a public certificate.
  openssl ca -config "${CA_DIR}/ca.ini" -extensions 'srv_cert' -days "${days}" -notext \
    -in "${CA_DIR}/ca/csr/${name}.csr" \
    -out "${CA_DIR}/ca/certs/${name}.crt" \
    && chmod 444 "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info on the display.
  openssl x509 -noout -text -in "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info to the file.
  openssl x509 -noout -text -in "${CA_DIR}/ca/certs/${name}.crt" > "${CA_DIR}/ca/certs/${name}.crt.info"

  # Verifying the public certificate on the display.
  openssl verify -CAfile "${CA_DIR}/ca/certs/ca.crt.chain" "${CA_DIR}/ca/certs/${name}.crt"
}

function gen_crt_usr() {
  local name; name="${1}"
  local days; days="${2:-740}"

  # Generating a private key.
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -out "${CA_DIR}/ca/private/${name}.key"

  # Generating a Certificate Signing Request (CSR).
  openssl req -config "${CA_DIR}/ca.ini" -new \
    -key "${CA_DIR}/ca/private/${name}.key" \
    -out "${CA_DIR}/ca/csr/${name}.csr"

  # Generating a public certificate.
  openssl ca -config "${CA_DIR}/ca.ini" -extensions 'usr_cert' -days "${days}" -notext \
    -in "${CA_DIR}/ca/csr/${name}.csr" \
    -out "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info on the display.
  openssl x509 -noout -text -in "${CA_DIR}/ca/certs/${name}.crt"

  # Generating public certificate info to the file.
  openssl x509 -noout -text -in "${CA_DIR}/ca/certs/${name}.crt" > "${CA_DIR}/ca/certs/${name}.crt.info"

  # Verifying the public certificate on the display.
  openssl verify -CAfile "${CA_DIR}/ca/certs/ca.crt.chain" "${CA_DIR}/ca/certs/${name}.crt"
}

function sig_crt_srv() {
  local name; name="${1}"
  local days; days="${2:-740}"

  # Generating a public certificate.
  openssl ca -config "${CA_DIR}/ca.ini" -extensions 'srv_cert' -days "${days}" -notext \
    -in "${name}" \
    -out "${CA_DIR}/ca/certs/${name}.crt"
}

function sig_crt_usr() {
  local name; name="${1}"
  local days; days="${2:-740}"

  # Generating a public certificate.
  openssl ca -config "${CA_DIR}/ca.ini" -extensions 'usr_cert' -days "${days}" -notext \
    -in "${name}" \
    -out "${CA_DIR}/ca/certs/${name}.crt"
}

"$@"
