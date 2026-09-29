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

# Parameters.
CN="${1:?}"
SAN="${2:?}"
DAYS="${3:?}"
EXT="${4:?}"

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function _title() {
  echo '' && echo "${1}" && echo ''
}

function _key() {
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -out "${SRC_DIR}/ca/key/${CN}.key"
}

function _csr() {
  openssl req -config "${SRC_DIR}/ca.ini" -new -addext "subjectAltName = ${SAN}" \
    -key "${SRC_DIR}/ca/key/ca.key" \
    -out "${SRC_DIR}/ca/csr/${CN}.csr"
}

function _crt() {
  openssl ca -config "${SRC_DIR}/ca.ini" -days "${DAYS}" -extensions "${EXT}" -notext \
    -in "${SRC_DIR}/ca/csr/${CN}.csr" \
    -out "${SRC_DIR}/ca/crt/${CN}.crt"
}

function _verify() {
  openssl verify -CAfile "${SRC_DIR}/ca/crt/ca.chain.crt" "${SRC_DIR}/ca/crt/${CN}.crt"
}

function _info() {
  openssl x509 -in "${SRC_DIR}/ca/crt/${CN}.crt" -text -noout
}

function generator() {
  _title "--- [SSL] SELF SIGNED CERTIFICATE: '${CN}'"
  _key && _csr && _crt && _verify && _info
}

function main() {
  generator
}; main "$@"
