#!/usr/bin/env -S bash -euo pipefail
# -------------------------------------------------------------------------------------------------------------------- #
# OPENSSL CA CERTIFICATE GENERATOR
# -------------------------------------------------------------------------------------------------------------------- #
# @package    Bash
# @author     Kai Kimera <mail@kai.kim>
# @license    MIT
# @version    0.1.0
# @link       https://libsys.ru/ru/2026/10/bc2ffc50-8d26-5150-bc98-951a81b17bbb/
# -------------------------------------------------------------------------------------------------------------------- #

(( EUID == 0 )) && { echo >&2 'This script should not be run as root!'; exit 1; }

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION
# -------------------------------------------------------------------------------------------------------------------- #

# Sources.
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P )"

# CA names.
CA_I='ca.1'

# Colors.
G='\033[0;32m'
Y='\033[0;33m'
NC='\033[0m'

CERT="${1}"

# -------------------------------------------------------------------------------------------------------------------- #
# -----------------------------------------------------< SCRIPT >----------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

function _title() {
  echo '' && echo -e "${Y}${1}${NC}" && echo ''
}

function _success() {
  echo '' && echo -e "${G}SUCCESSFULLY COMPLETED!${NC}" >&2 && echo ''
}

function _revoke() {
  local d=('crt' 'csr' 'key' 'pfx')
  _title "--- [SSL] CERTIFICATE REVOCATION: '${CERT}'"
  openssl ca -config "${SRC_DIR}/${1}" -revoke "${SRC_DIR}/${CA_I}/crt/${2}/${2}.crt" \
    && for i in "${d[@]}"; do mv "${SRC_DIR}/${CA_I}/${i}/${2}" "${SRC_DIR}/${CA_I}/${i}/${2}.R"; done
}

function _crl() {
  _title "--- [SSL-CA/${2^^}] GENERATING A CRL FILE"
  openssl ca -config "${SRC_DIR}/${1}" -gencrl -out "${SRC_DIR}/${CA_I}/crl/${2}.crl"
}

function main() {
  _revoke "${CA_I}.ini" "${CERT}" \
    && _crl "${CA_I}.ini" "${CA_I}"
}; main "$@"
