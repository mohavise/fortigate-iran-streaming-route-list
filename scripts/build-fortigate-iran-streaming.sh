#!/usr/bin/env bash
set -euo pipefail

# managed-by=mohavise-fortigate-iran-streaming-route-list
# project=fortigate-iran-streaming-route-list
# source=mikrotik-iran-streaming-route-list

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_URL="${SOURCE_URL:-https://raw.githubusercontent.com/mohavise/mikrotik-iran-streaming-route-list/main/iran-streaming-domains.txt}"
DOMAIN_FEED="$ROOT_DIR/fortigate-iran-streaming-domains.txt"
OBJECTS_FILE="$ROOT_DIR/fortigate-iran-streaming-address-objects.conf"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

normalize_name() {
  printf '%s' "$1" \
    | tr '[:lower:]' '[:upper:]' \
    | sed -E 's/[^A-Z0-9]+/-/g; s/^-+//; s/-+$//'
}

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

{
  while IFS= read -r domain; do
    [ -z "$domain" ] && continue
    echo "$domain"
    echo "*.$domain"
  done < "$TMP_FILE"
} > "$DOMAIN_FEED"

{
  echo '# managed-by=mohavise-fortigate-iran-streaming-route-list'
  echo '# project=fortigate-iran-streaming-route-list'
  echo '# source=mikrotik-iran-streaming-route-list'
  echo '# output=fortigate-fqdn-address-objects'
  echo '# do-not-edit-manually'
  echo
  echo 'config firewall address'
  while IFS= read -r domain; do
    [ -z "$domain" ] && continue
    name="IRSTR-$(normalize_name "$domain")"
    wild_name="${name}-WILD"
    echo "    edit \"$name\""
    echo '        set type fqdn'
    echo "        set fqdn \"$domain\""
    echo '    next'
    echo "    edit \"$wild_name\""
    echo '        set type fqdn'
    echo "        set fqdn \"*.$domain\""
    echo '    next'
  done < "$TMP_FILE"
  echo 'end'
  echo
  echo 'config firewall addrgrp'
  echo '    edit "GRP-IRAN-STREAMING"'
  printf '        set member'
  while IFS= read -r domain; do
    [ -z "$domain" ] && continue
    name="IRSTR-$(normalize_name "$domain")"
    wild_name="${name}-WILD"
    printf ' "%s" "%s"' "$name" "$wild_name"
  done < "$TMP_FILE"
  echo
  echo '    next'
  echo 'end'
} > "$OBJECTS_FILE"

feed_count="$(wc -l < "$DOMAIN_FEED" | tr -d ' ')"
echo "source domains: $count"
echo "feed entries: $feed_count"
echo "domain feed: $DOMAIN_FEED"
echo "address objects: $OBJECTS_FILE"
