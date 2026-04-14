#!/bin/bash

set -u # forbid undefined variables
set -e # forbid command failure

readonly PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH

if ! command -v security >/dev/null 2>&1; then
  echo
  exit 0
fi

readonly IDENTITIES="$(security find-identity -p codesigning -v || true)"

if [[ -n "${PQRS_ORG_CODE_SIGN_IDENTITY:-}" ]]; then
  if grep -q ") $PQRS_ORG_CODE_SIGN_IDENTITY \"" <<<"$IDENTITIES"; then
    echo $PQRS_ORG_CODE_SIGN_IDENTITY
    exit 0
  fi
fi

find_identity() {
  local pattern="$1"

  awk -v pattern="$pattern" '
    $0 ~ pattern {
      if (match($0, /[0-9A-F]{40}/)) {
        print substr($0, RSTART, RLENGTH)
        exit
      }
    }
  ' <<<"$IDENTITIES"
}

for pattern in \
  'Developer ID Application:' \
  'Apple Development:' \
  'Apple Distribution:'
do
  identity="$(find_identity "$pattern")"
  if [[ -n "$identity" ]]; then
    echo "$identity"
    exit 0
  fi
done

echo
