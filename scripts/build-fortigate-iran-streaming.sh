#!/usr/bin/env bash
set -euo pipefail

# managed-by=mohavise-fortigate-iran-streaming-route-list
# project=fortigate-iran-streaming-route-list
# source=mikrotik-iran-streaming-route-list

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_URL="${SOURCE_URL:-https://raw.githubusercontent.com/mohavise/mikrotik-iran-streaming-route-list/main/iran-streaming-domains.txt}"
OUT_FILE="$ROOT_DIR/fortigate-iran-streaming-domains.txt"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

curl -fsSL "$SOURCE_URL" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/#.*$//; s#^https?://##; s#/.*$##; s/:.*$//; s/^\*\.//; s/[[:space:]]//g' \
  | sed '/^$/d' \
  | grep -E '^[a-z0-9.-]+\.[a-z]{2,}$' \
  | sort -u > "$TMP_FILE"

count="$(wc -l < "$TMP_FILE" | tr -d ' ')"
if [ "$count" -lt 5 ]; then
  echo "FortiGate Iran streaming feed: too few domains ($count); stopping" >&2
  exit 1
fi

mv "$TMP_FILE" "$OUT_FILE"
echo "domains: $count"
echo "output: $OUT_FILE"
