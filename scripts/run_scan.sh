#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load PROFILE_ID and DATASTREAM_PATH
SCAN_ENV="${SCAN_ENV:-$SCRIPT_DIR/scan.env}"
if [ ! -f "$SCAN_ENV" ]; then
  echo "ERROR: scan.env not found at $SCAN_ENV" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$SCAN_ENV"

OUT_DIR="${1:-/tmp/openscap}"
mkdir -p "$OUT_DIR"

ARF_FILE="$OUT_DIR/results.arf.xml"
HTML_FILE="$OUT_DIR/report.html"

echo "Profile:    $PROFILE_ID"
echo "Datastream: $DATASTREAM_PATH"
echo "Output dir: $OUT_DIR"

# oscap exit codes:
#   0 = all rules passed
#   1 = error running the tool
#   2 = scan completed but one or more rules FAILED  <-- normal for a baseline
# We must not let a "2" abort the script, so we capture the code manually.
set +e
sudo oscap xccdf eval \
  --profile "$PROFILE_ID" \
  --results-arf "$ARF_FILE" \
  --report "$HTML_FILE" \
  "$DATASTREAM_PATH"
OSCAP_RC=$?
set -e

if [ "$OSCAP_RC" -eq 1 ]; then
  echo "ERROR: oscap evaluation failed (exit code 1)" >&2
  exit 1
fi

# Make results world-readable so the Ansible fetch (any user) can pull them.
sudo chmod 0644 "$ARF_FILE" "$HTML_FILE"

echo "Scan finished (oscap rc=$OSCAP_RC — rc=2 just means some rules failed, expected)."
echo "ARF:  $ARF_FILE"
echo "HTML: $HTML_FILE"
