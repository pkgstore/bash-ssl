#!/usr/bin/env -S bash -euo pipefail
# -------------------------------------------------------------------------------------------------------------------- #
# OPENSSL CA
# -------------------------------------------------------------------------------------------------------------------- #
# @package    Bash
# @author     Kai Kimera <mail@kai.kim>
# @license    MIT
# @version    0.1.0
# @link       https://libsys.ru/ru/2023/10/6733cb51-62a0-5ed9-b421-8f08c4e0cb18/
# -------------------------------------------------------------------------------------------------------------------- #

(( EUID == 0 )) && { echo >&2 'This script should not be run as root!'; exit 1; }

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION
# -------------------------------------------------------------------------------------------------------------------- #

# Variables.
CA_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P )"

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function _title() {
  echo '' && echo "${1}" && echo ''
}

function _struct() {
  _title '--- [SSL-CA] CREATING A STRUCTURE'
  mkdir -p "${CA_DIR}/${1}"/{certs,certs.new,crl,csr,private} \
    && touch "${CA_DIR}/${1}/index.txt" \
    && echo '1000' > "${CA_DIR}/${1}/serial" \
    && echo '1000' > "${CA_DIR}/${1}/crlnumber"
}

function _key() {
  _title '--- [SSL] GENERATING A PRIVATE KEY'
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -aes256 -out "${CA_DIR}/${1}/private/${1}.key"
}

function _csr() {
  _title '--- [SSL] GENERATING A CERTIFICATE SIGNING REQUEST (CSR)'
  openssl req -config "${CA_DIR}/${1}.ini" -new \
  -key "${CA_DIR}/${1}/private/${1}.key" \
  -out "${CA_DIR}/${1}/csr/${1}.csr"
}

function _cert() {
  _title '--- [SSL] GENERATING A CERTIFICATE'
  case "${1}" in
    'ca.root')
      openssl req -config "${CA_DIR}/${2}" -extensions "${3}" -new -x509 -days "${4}" \
        -key "${CA_DIR}/${1}/private/${1}.key" \
        -out "${CA_DIR}/${1}/certs/${1}.crt"
      ;;
    'ca')
      openssl ca -config "${CA_DIR}/${2}" -extensions "${3}" -days "${4}" -notext \
        -in "${CA_DIR}/${1}/csr/${1}.csr" \
        -out "${CA_DIR}/${1}/certs/${1}.crt"
      ;;
    *) echo "'TYPE' does not exist!"; exit 1 ;;
  esac
}

function _verify() {
  openssl verify -CAfile "${CA_DIR}/${1}/certs/${1}.crt" "${CA_DIR}/${2}/certs/${2}.crt"
}

function _chain() {
  cat "${CA_DIR}/${2}/certs/${2}.crt" "${CA_DIR}/${1}/certs/${1}.crt" \
    > "${CA_DIR}/${2}/certs/${2}.crt.chain"
}

function _info() {
  openssl x509 -noout -text -in "${CA_DIR}/${1}/certs/${1}.crt" \
  && openssl x509 -noout -text -in "${CA_DIR}/${1}/certs/${1}.crt" > "${CA_DIR}/${1}/certs/${1}.crt.info"
}

function init_ca_root() {
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
#copy_extensions = copy

# The root key and root certificate.
private_key                     = \$dir/private/ca.root.key
certificate                     = \$dir/certs/ca.root.crt

# For certificate revocation lists.
crlnumber                       = \$dir/crlnumber
crl                             = \$dir/ca.root.crl
crl_extensions                  = crl_ext
default_crl_days                = 30

# SHA-1 is deprecated, so use SHA-2 or SHA-3 instead.
default_md                      = sha256

name_opt                        = ca_default
cert_opt                        = ca_default
default_days                    = 3650
preserve                        = no
policy                          = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of \`man ca\`.
countryName                     = match
stateOrProvinceName             = match
organizationName                = match
organizationalUnitName          = optional
commonName                      = supplied
emailAddress                    = optional

[ policy_loose ]
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
default_bits                    = 2048
distinguished_name              = req_distinguished_name
string_mask                     = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md                      = sha256

# Extension to add when the -x509 option is used.
x509_extensions                 = v3_ca_root

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
commonName                      = Common Name
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = SC
stateOrProvinceName_default     = Victoria
localityName_default            = Victoria
0.organizationName_default      = LocalHost
organizationalUnitName_default  = LocalHost Root CA
emailAddress_default            = mail@localhost

[ v3_ca_root ]
# Extensions for a typical CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true
keyUsage                        = critical, digitalSignature, cRLSign, keyCertSign

[ v3_ca_intermediate ]
# Extensions for a typical intermediate CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true, pathlen:0
keyUsage                        = critical, digitalSignature, cRLSign, keyCertSign

[ cert ]
# Extensions for client certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
nsCertType                      = server, client
nsComment                       = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
keyUsage                        = critical, digitalSignature, nonRepudiation, keyEncipherment
extendedKeyUsage                = serverAuth, clientAuth
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

  _struct 'ca.root' \
  && _key 'ca.root' \
  && _cert 'ca.root' 'ca.root.ini' 'v3_ca_root' '7310' \
  && _info 'ca.root'
}

function init_ca_intermediate() {
  _title '--- [SSL-CA] GENERATING A CONFIGURATION FILE'
  cp "${CA_DIR}/ca.root.ini" "${CA_DIR}/ca.ini"
  sed -i \
    -e 's|ca.root|ca|g' \
    -e 's|Root CA|Intermediate CA|g' \
    -e 's|= policy_strict|= policy_loose|g' \
    -e 's|#copy_extensions =|copy_extensions =|g' "${CA_DIR}/ca.ini"

  _struct 'ca' \
  && _key 'ca' \
  && _csr 'ca' 'ca' \
  && _cert 'ca' 'ca.root.ini' 'v3_ca_intermediate' '3650' \
  && _verify 'ca.root' 'ca' \
  && _chain 'ca.root' 'ca' \
  && _info 'ca'
}

"$@"
