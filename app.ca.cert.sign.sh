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
CSR="${2:?}"
DAYS="${3:?}"
EXT="${4:?}"

# CA names.
CA_I='ca.01'

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

function _crt() {
  _title "--- [SSL] GENERATING A CRT FILE: '${CN}'"
  openssl ca -config "${SRC_DIR}/${CA_I}.ini" -days "${DAYS}" -extensions "${EXT}" -notext \
    -in "${CSR}" -out "${SRC_DIR}/${CA_I}/crt/${CN}.crt" \
    && chmod 444 "${SRC_DIR}/${CA_I}/crt/${CN}.crt" \
    && _success
}

function _verify() {
  _title "--- [SSL] VERIFICATION: '${CN}'"
  openssl verify -CAfile "${SRC_DIR}/${CA_I}/crt/${CA_I}.chain.crt" "${SRC_DIR}/${CA_I}/crt/${CN}.crt" \
    && _success
}

function _chain() {
  _title "--- [SSL-CA] GENERATING A CHAIN FILE"
  cat "${SRC_DIR}/${CA_I}/crt/${CN}.crt" "${SRC_DIR}/${CA_I}/crt/${CA_I}.chain.crt" \
    > "${SRC_DIR}/${CA_I}/crt/${CN}.chain.crt" \
    && chmod 444 "${SRC_DIR}/${CA_I}/crt/${CN}.chain.crt" \
    && _success
}

function _info() {
  _title "--- [SSL] GENERATING A INFO FILE: '${CN}'"
  openssl x509 -noout -text -in "${SRC_DIR}/${CA_I}/crt/${CN}.crt" > "${SRC_DIR}/${CA_I}/crt/${CN}.crt.info" \
    && _success
}

function generator() {
  _crt \
    && _verify \
    && _chain \
    && _info
}

function main() {
  generator
}; main "$@"
