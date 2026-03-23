#!/usr/bin/env bash
# Smoke-test Places Autocomplete with the project root .env key.
# Usage: bash tool/google_places_autocomplete_curl.sh "Berlin"
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT="${1:-Berlin}"
KEY="$(grep -E '^GOOGLE_MAPS_API_KEY=' "$ROOT/.env" | cut -d= -f2- | tr -d '\r')"
if [[ -z "$KEY" ]]; then
  echo "No GOOGLE_MAPS_API_KEY in $ROOT/.env"
  exit 1
fi
echo "=== Masked key preview: AIzaSy...${KEY: -4} ==="
echo "=== Response ==="
curl -sS -G "https://maps.googleapis.com/maps/api/place/autocomplete/json" \
  --data-urlencode "input=${INPUT}" \
  --data-urlencode "key=${KEY}" \
  -w "\nHTTP_CODE:%{http_code}\n"
