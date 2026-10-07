#!/usr/bin/env -S bash -euo pipefail
# -------------------------------------------------------------------------------------------------------------------- #
# OPENSSL CA CERTIFICATE GENERATOR
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

# Timestamp.
TS="$( date '+%s' )"

# Parameters.
CN="${1:?}.${TS}"
SAN="${2:?}"
DAYS="${3:?}"
EXT="${4:?}"

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

function _key() {
  _title "--- [SSL] GENERATING A KEY FILE: '${CN}'"
  [[ ! -d "${SRC_DIR}/${CA_I}/key/${CN}" ]] && mkdir "${SRC_DIR}/${CA_I}/key/${CN}"
  openssl ecparam -genkey -name 'prime256v1' | openssl ec -out "${SRC_DIR}/${CA_I}/key/${CN}/${CN}.key" \
    && chmod 400 "${SRC_DIR}/${CA_I}/key/${CN}/${CN}.key" \
    && _success
}

function _csr() {
  _title "--- [SSL] GENERATING A CSR FILE: '${CN}'"
  [[ ! -d "${SRC_DIR}/${CA_I}/csr/${CN}" ]] && mkdir "${SRC_DIR}/${CA_I}/csr/${CN}"
  openssl req -config "${SRC_DIR}/${CA_I}.ini" -new -addext "subjectAltName = ${SAN}" \
    -key "${SRC_DIR}/${CA_I}/key/${CN}/${CN}.key" -out "${SRC_DIR}/${CA_I}/csr/${CN}/${CN}.csr" \
    && _success
}

function _crt() {
  _title "--- [SSL] GENERATING A CRT FILE: '${CN}'"
  [[ ! -d "${SRC_DIR}/${CA_I}/crt/${CN}" ]] && mkdir "${SRC_DIR}/${CA_I}/crt/${CN}"
  openssl ca -config "${SRC_DIR}/${CA_I}.ini" -days "${DAYS}" -extensions "${EXT}" -notext \
    -in "${SRC_DIR}/${CA_I}/csr/${CN}/${CN}.csr" -out "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" \
    && chmod 444 "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" \
    && _success
}

function _verify() {
  _title "--- [SSL] VERIFICATION: '${CN}'"
  openssl verify -CAfile "${SRC_DIR}/${CA_I}/crt/${CA_I}.chain.crt" "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" \
    && _success
}

function _chain() {
  _title "--- [SSL-CA] GENERATING A CHAIN FILE: '${CN}'"
  cat "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" "${SRC_DIR}/${CA_I}/crt/${CA_I}.chain.crt" \
    > "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.chain.crt" \
    && chmod 444 "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.chain.crt" \
    && _success
}

function _info() {
  _title "--- [SSL] GENERATING A INFO FILE: '${CN}'"
  openssl x509 -noout -text -in "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" \
    > "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt.info" \
    && _success
}

function _pkcs() {
  _title "--- [SSL] GENERATING A PFX FILE: '${CN}'"
  [[ ! -d "${SRC_DIR}/${CA_I}/pfx/${CN}" ]] && mkdir "${SRC_DIR}/${CA_I}/pfx/${CN}"
  openssl pkcs12 -export \
    -out "${SRC_DIR}/${CA_I}/pfx/${CN}/${CN}.pfx" \
    -inkey "${SRC_DIR}/${CA_I}/key/${CN}/${CN}.key" \
    -in "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" \
    -certfile "${SRC_DIR}/${CA_I}/crt/${CA_I}.crt" \
    -certfile "${SRC_DIR}/${CA_R}/crt/${CA_R}.crt" \
    && chmod 444 "${SRC_DIR}/${CA_I}/pfx/${CN}/${CN}.pfx" \
    && _success
}

function _pkcs_compat() {
  _title "--- [SSL] GENERATING A PFX FILE (COMPATIBILITY): '${CN}'"
  [[ ! -d "${SRC_DIR}/${CA_I}/pfx/${CN}" ]] && mkdir "${SRC_DIR}/${CA_I}/pfx/${CN}"
  openssl pkcs12 -export -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 \
    -out "${SRC_DIR}/${CA_I}/pfx/${CN}/${CN}.compat.pfx" \
    -inkey "${SRC_DIR}/${CA_I}/key/${CN}/${CN}.key" \
    -in "${SRC_DIR}/${CA_I}/crt/${CN}/${CN}.crt" \
    -certfile "${SRC_DIR}/${CA_I}/crt/${CA_I}.crt" \
    -certfile "${SRC_DIR}/${CA_R}/crt/${CA_R}.crt" \
    && chmod 444 "${SRC_DIR}/${CA_I}/pfx/${CN}/${CN}.compat.pfx" \
    && _success
}

function main() {
  _key \
    && _csr \
    && _crt \
    && _verify \
    && _chain \
    && _info \
    && _pkcs \
    && _pkcs_compat
}; main "$@"
