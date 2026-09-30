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
CA='ca.01'

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function _title() {
  echo '' && echo "${1}" && echo ''
}

function _key() {
  openssl ecparam -genkey -name 'secp384r1' | openssl ec -out "${SRC_DIR}/${CA}/key/${CN}.key"
}

function _csr() {
  openssl req -config "${SRC_DIR}/${CA}.ini" -new -addext "subjectAltName = ${SAN}" \
    -key "${SRC_DIR}/${CA}/key/${CA}.key" -out "${SRC_DIR}/${CA}/csr/${CN}.csr"
}

function _crt() {
  openssl ca -config "${SRC_DIR}/${CA}.ini" -days "${DAYS}" -extensions "${EXT}" -notext \
    -in "${SRC_DIR}/${CA}/csr/${CN}.csr" -out "${SRC_DIR}/${CA}/crt/${CN}.crt"
}

function _verify() {
  openssl verify -CAfile "${SRC_DIR}/${CA}/crt/${CA}.chain.crt" "${SRC_DIR}/${CA}/crt/${CN}.crt"
}

function _info() {
  openssl x509 -in "${SRC_DIR}/${CA}/crt/${CN}.crt" -text -noout
}

function _pkcs() {
  openssl pkcs12 -export -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -nomac \
    -inkey "${f}.key" -in "${f}.crt" -out "${f}.pfx"
}

function generator() {
  _title "--- [SSL] SELF SIGNED CERTIFICATE: '${CN}'"
  _key && _csr && _crt && _verify && _info
}

function main() {
  generator
}; main "$@"
