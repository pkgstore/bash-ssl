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

# CA names.
CA_R='ca.0'
CA_I='ca.1'

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
  echo '' && echo -e "${G}SUCCESSFULLY COMPLETED!${NC}" >&2 && echo ''
}

function _conf() {
  cat > "${SRC_DIR}/${CA_R}.ini" <<EOF
[ ca ]
default_ca                      = CA_default

[ CA_default ]
# Directory and file locations.
dir                             = ${SRC_DIR}/${CA_R}
certs                           = \$dir/crt
crl_dir                         = \$dir/crl
new_certs_dir                   = \$dir/crt.new
database                        = \$dir/index.txt
serial                          = \$dir/serial
RANDFILE                        = \$dir/key/.rand
#copy_extensions = copy

# The root key and root certificate.
private_key                     = \$dir/key/${CA_R}.key
certificate                     = \$dir/crt/${CA_R}.crt

# For certificate revocation lists.
crlnumber                       = \$dir/crlnumber
crl                             = \$dir/${CA_R}.crl
crl_extensions                  = crl_ext
default_crl_days                = 30

# SHA-1 is deprecated, so use SHA-2 or SHA-3 instead.
default_md                      = sha384

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
default_md                      = sha384

# Extension to add when the -x509 option is used.
x509_extensions                 = v3_ca_0

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
commonName_default              = LocalHost Root CA
countryName_default             = SC
stateOrProvinceName_default     = Victoria
localityName_default            = Victoria
0.organizationName_default      = LocalHost
organizationalUnitName_default  = IT Department
emailAddress_default            = mail@localhost

[ v3_ca_0 ]
# Extensions for a typical CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true, pathlen:4
keyUsage                        = critical, digitalSignature, keyCertSign, cRLSign

[ v3_ca_1 ]
# Extensions for a typical intermediate CA (\`man x509v3_config\`).
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always,issuer
basicConstraints                = critical, CA:true, pathlen:0
keyUsage                        = critical, digitalSignature, keyCertSign, cRLSign

[ cert_code ]
# Extensions for code certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer
keyUsage                        = critical, digitalSignature, nonRepudiation
extendedKeyUsage                = critical, codeSigning

[ cert_client ]
# Extensions for client certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer
keyUsage                        = critical, digitalSignature, keyEncipherment, nonRepudiation
extendedKeyUsage                = clientAuth, emailProtection

[ cert_server ]
# Extensions for server certificates (\`man x509v3_config\`).
basicConstraints                = CA:FALSE
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
keyUsage                        = critical, digitalSignature, keyEncipherment, nonRepudiation
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
}

function _struct() {
  _title "--- [SSL-CA/${1^^}] CREATING A STRUCTURE"
  local d=('crl' 'crt' 'crt.new' 'csr' 'key' 'pfx')
  for i in "${d[@]}"; do mkdir -p "${SRC_DIR}/${1}/${i}"; done \
    && chmod 700 "${SRC_DIR}/${1}/key" \
    && touch "${SRC_DIR}/${1}/index.txt" \
    && echo '1000' > "${SRC_DIR}/${1}/serial" \
    && echo '1000' > "${SRC_DIR}/${1}/crlnumber" \
    && _success
}

function _key() {
  _title "--- [SSL-CA/${1^^}] GENERATING A KEY FILE"
  openssl ecparam -name 'secp384r1' -genkey -noout | openssl ec -aes256 -out "${SRC_DIR}/${1}/key/${1}.key" \
    && chmod 400 "${SRC_DIR}/${1}/key/${1}.key" \
    && _success
}

function _csr() {
  _title "--- [SSL-CA/${1^^}] GENERATING A CSR FILE"
  openssl req -config "${SRC_DIR}/${1}" -new \
    -key "${SRC_DIR}/${2}/key/${2}.key" -out "${SRC_DIR}/${2}/csr/${2}.csr" \
    && _success
}

function _crt() {
  _title "--- [SSL-CA/${2^^}] GENERATING A CRT FILE"
  case "${2}" in
    'ca.0')
      openssl req -config "${SRC_DIR}/${1}" -extensions "${3}" -new -x509 -days "${4}" \
        -key "${SRC_DIR}/${2}/key/${2}.key" -out "${SRC_DIR}/${2}/crt/${2}.crt" \
        && _success
      ;;
    'ca.1')
      openssl ca -config "${SRC_DIR}/${1}" -extensions "${3}" -days "${4}" -notext \
        -in "${SRC_DIR}/${2}/csr/${2}.csr" -out "${SRC_DIR}/${2}/crt/${2}.crt" \
        && _success
      ;;
    *) echo "'TYPE' does not exist!"; exit 1 ;;
  esac
  [[ -f "${SRC_DIR}/${2}/crt/${2}.crt" ]] && chmod 444 "${SRC_DIR}/${2}/crt/${2}.crt"
}

function _verify() {
  _title "--- [SSL-CA/${2^^}] VERIFICATION"
  openssl verify -CAfile "${SRC_DIR}/${1}/crt/${1}.crt" "${SRC_DIR}/${2}/crt/${2}.crt" \
    && _success
}

function _chain() {
  _title "--- [SSL-CA/${2^^}] GENERATING A CHAIN FILE"
  cat "${SRC_DIR}/${2}/crt/${2}.crt" "${SRC_DIR}/${1}/crt/${1}.crt" > "${SRC_DIR}/${2}/crt/${2}.chain.crt" \
    && chmod 444 "${SRC_DIR}/${2}/crt/${2}.chain.crt" \
    && _success
}

function _info() {
  _title "--- [SSL-CA/${1^^}] GENERATING A INFO FILE"
  openssl x509 -noout -text -in "${SRC_DIR}/${1}/crt/${1}.crt" > "${SRC_DIR}/${1}/crt/${1}.crt.info" \
    && _success
}

function _crl() {
  _title "--- [SSL-CA/${2^^}] GENERATING A CRL FILE"
  openssl ca -config "${SRC_DIR}/${1}" -gencrl -out "${SRC_DIR}/${2}/crl/${2}.crl"
}

function ca_0() {
  _conf \
    && _struct "${CA_R}" \
    && _key "${CA_R}" \
    && _crt "${CA_R}.ini" "${CA_R}" 'v3_ca_0' '7310' \
    && _info "${CA_R}"
}

function ca_1() {
  cp "${SRC_DIR}/${CA_R}.ini" "${SRC_DIR}/${CA_I}.ini" \
    && sed -i \
      -e "s|${CA_R}|${CA_I}|g" \
      -e 's|Root CA|Sub CA|g' \
      -e 's|= policy_strict|= policy_loose|g' \
      -e 's|#copy_extensions =|copy_extensions =|g' "${SRC_DIR}/${CA_I}.ini"

  _struct "${CA_I}" \
    && _key "${CA_I}" \
    && _csr "${CA_I}.ini" "${CA_I}" \
    && _crt "${CA_R}.ini" "${CA_I}" 'v3_ca_1' '3650' \
    && _verify "${CA_R}" "${CA_I}" \
    && _chain "${CA_R}" "${CA_I}" \
    && _info "${CA_I}" \
    && _crl "${CA_I}.ini" "${CA_I}"
}

function main() {
  ca_0 && ca_1
}; main "$@"
