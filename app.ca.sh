#!/usr/bin/env -S bash -euo pipefail
# -------------------------------------------------------------------------------------------------------------------- #
# OPENSSL CA GENERATOR
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

# Sources.
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P )"

# Colors.
G='\033[0;32m'
Y='\033[0;33m'
NC='\033[0m'

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function _title() {
  echo '' && echo -e "${Y}${1}${NC}" && echo ''
}

function _success() {
  echo '' && echo -e "${G}Successfully completed!${NC}" >&2 && echo ''
}

function _struct() {
  _title '--- [SSL-CA] CREATING A STRUCTURE'
  mkdir -p "${SRC_DIR}/${1}"/{crt,crt.new,crl,csr,key} \
    && touch "${SRC_DIR}/${1}/index.txt" \
    && echo '1000' > "${SRC_DIR}/${1}/serial" \
    && echo '1000' > "${SRC_DIR}/${1}/crlnumber" \
    && _success
}

function _key() {
  _title "--- [SSL-CA] GENERATING A KEY FILE"
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -aes256 -out "${SRC_DIR}/${1}/key/${1}.key" && _success
}

function _csr() {
  _title "--- [SSL-CA] GENERATING A CSR FILE"
  openssl req -config "${SRC_DIR}/${1}.ini" -new \
    -key "${SRC_DIR}/${1}/key/${1}.key" -out "${SRC_DIR}/${1}/csr/${1}.csr" \
    && _success
}

function _crt() {
  _title "--- [SSL-CA] GENERATING A CRT FILE"
  case "${1}" in
    'ca.00')
      openssl req -config "${SRC_DIR}/${2}" -extensions "${3}" -new -x509 -days "${4}" \
        -key "${SRC_DIR}/${1}/key/${1}.key" \
        -out "${SRC_DIR}/${1}/crt/${1}.crt" \
        && _success
      ;;
    'ca.01')
      openssl ca -config "${SRC_DIR}/${2}" -extensions "${3}" -days "${4}" -notext \
        -in "${SRC_DIR}/${1}/csr/${1}.csr" \
        -out "${SRC_DIR}/${1}/crt/${1}.crt" \
        && _success
      ;;
    *) echo "'TYPE' does not exist!"; exit 1 ;;
  esac
}

function _verify() {
  _title "--- [SSL-CA] VERIFICATION"
  openssl verify -CAfile "${SRC_DIR}/${1}/crt/${1}.crt" "${SRC_DIR}/${2}/crt/${2}.crt" \
    && _success
}

function _chain() {
  _title "--- [SSL-CA] GENERATING A CHAIN FILE"
  cat "${SRC_DIR}/${2}/crt/${2}.crt" "${SRC_DIR}/${1}/crt/${1}.crt" > "${SRC_DIR}/${2}/crt/${2}.chain.crt" \
    && _success
}

function _info() {
  _title "--- [SSL-CA] INFORMATION"
  openssl x509 -noout -text -in "${SRC_DIR}/${1}/crt/${1}.crt" \
    && openssl x509 -noout -text -in "${SRC_DIR}/${1}/crt/${1}.crt" > "${SRC_DIR}/${1}/crt/${1}.crt.info" \
    && _success
}

function init_ca_00() {
  local ca='ca.00'

  cat > "${SRC_DIR}/${ca}.ini" <<EOF
[ ca ]
default_ca                      = CA_default

[ CA_default ]
# Directory and file locations.
dir                             = ${SRC_DIR}/${ca}
certs                           = \$dir/crt
crl_dir                         = \$dir/crl
new_certs_dir                   = \$dir/crt.new
database                        = \$dir/index.txt
serial                          = \$dir/serial
RANDFILE                        = \$dir/key/.rand
#copy_extensions = copy

# The root key and root certificate.
private_key                     = \$dir/key/${ca}.key
certificate                     = \$dir/crt/${ca}.crt

# For certificate revocation lists.
crlnumber                       = \$dir/crlnumber
crl                             = \$dir/${ca}.crl
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
x509_extensions                 = v3_ca_00

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

[ v3_ca_00 ]
# Extensions for a typical CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true
keyUsage                        = critical, digitalSignature, cRLSign, keyCertSign

[ v3_ca_01 ]
# Extensions for a typical intermediate CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true, pathlen:0
keyUsage                        = critical, digitalSignature, cRLSign, keyCertSign

[ cert_user ]
# Extensions for client certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
nsCertType                      = client, email
nsComment                       = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer
keyUsage                        = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage                = clientAuth, emailProtection

[ cert_server ]
# Extensions for server certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
nsCertType                      = server
nsComment                       = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
keyUsage                        = critical, digitalSignature, keyEncipherment
extendedKeyUsage                = serverAuth

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

  _struct "${ca}" \
    && _key "${ca}" \
    && _crt "${ca}" "${ca}.ini" 'v3_ca_00' '7310' \
    && _info "${ca}"
}

function init_ca_01() {
  local ca_r='ca.00'; local ca_i='ca.01'

  cp "${SRC_DIR}/${ca_r}.ini" "${SRC_DIR}/${ca_i}.ini"
  sed -i \
    -e "s|${ca_r}|${ca_i}|g" \
    -e 's|Root CA|Intermediate CA|g' \
    -e 's|= policy_strict|= policy_loose|g' \
    -e 's|#copy_extensions =|copy_extensions =|g' "${SRC_DIR}/${ca_i}.ini"

  _struct "${ca_i}" \
    && _key "${ca_i}" \
    && _csr "${ca_i}" "${ca_i}" \
    && _crt "${ca_i}" "${ca_r}.ini" 'v3_ca_01' '3650' \
    && _verify "${ca_r}" "${ca_i}" \
    && _chain "${ca_r}" "${ca_i}" \
    && _info "${ca_i}"
}

"$@"
