#!/usr/bin/env bash
set -euo pipefail

# managed-by=mohavise-fortigate-iran-streaming-route-list
# project=fortigate-iran-streaming-route-list
# source=mikrotik-iran-streaming-route-list

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_URL="${SOURCE_URL:-https://raw.githubusercontent.com/mohavise/mikrotik-iran-streaming-route-list/main/iran-streaming-domains.txt}"
DOMAIN_FEED="${DOMAIN_FEED:-$ROOT_DIR/fortigate-iran-streaming-domains.txt}"
OBJECTS_FILE="${OBJECTS_FILE:-$ROOT_DIR/fortigate-iran-streaming-address-objects.conf}"
MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-5}"
MAX_DROP_PERCENT="${MAX_DROP_PERCENT:-20}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

case "$SOURCE_URL" in
  https://*) ;;
  *) echo "Source URL must use HTTPS: $SOURCE_URL" >&2; exit 1 ;;
esac

normalize_name() {
  printf '%s' "$1" |
    tr '[:lower:]' '[:upper:]' |
    sed -E 's/[^A-Z0-9]+/-/g; s/^-+//; s/-+$//'
}

validate_domains() {
  local input_file="$1"
  local output_file="$2"
  local invalid_file="$3"

  awk -v invalid_file="$invalid_file" '
    function valid_domain(domain, labels, count, i, label, tld) {
      if (domain == "" || length(domain) > 253) return 0
      if (domain ~ /[[:space:]]/ || domain ~ /\.\./) return 0
      if (domain ~ /^\./ || domain ~ /\.$/) return 0
      if (domain ~ /^[0-9]+(\.[0-9]+){3}$/) return 0
      if (domain !~ /^[a-z0-9.-]+$/) return 0

      count = split(domain, labels, ".")
      if (count < 2) return 0
      for (i = 1; i <= count; i++) {
        label = labels[i]
        if (label == "" || length(label) > 63) return 0
        if (label ~ /^-/ || label ~ /-$/) return 0
        if (label !~ /^[a-z0-9-]+$/) return 0
      }

      tld = labels[count]
      if (length(tld) < 2 || length(tld) > 63) return 0
      if (tld !~ /^[a-z]+$/) return 0
      return 1
    }

    {
      original = $0
      line = tolower($0)
      gsub(/\r/, "", line)
      sub(/#.*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      sub(/^https?:\/\//, "", line)
      sub(/\/.*/, "", line)
      sub(/:[0-9]+$/, "", line)
      sub(/^\*\./, "", line)
      sub(/\.$/, "", line)

      if (line == "") next
      if (valid_domain(line)) print line
      else print original >> invalid_file
    }
  ' "$input_file" | LC_ALL=C sort -u > "$output_file"
}

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --retry 5 \
  --retry-all-errors \
  --retry-delay 5 \
  --connect-timeout 20 \
  --max-time 120 \
  --user-agent "mohavise-fortigate-iran-streaming-route-list/1.0" \
  "$SOURCE_URL" > "$TMP_DIR/source.txt"

: > "$TMP_DIR/invalid.txt"
validate_domains "$TMP_DIR/source.txt" "$TMP_DIR/domains.txt" "$TMP_DIR/invalid.txt"

if [[ -s "$TMP_DIR/invalid.txt" ]]; then
  echo "Invalid source entries detected; refusing to publish:" >&2
  sed -n '1,20p' "$TMP_DIR/invalid.txt" >&2
  exit 1
fi

count="$(wc -l < "$TMP_DIR/domains.txt" | tr -d ' ')"
if (( count < MIN_DOMAIN_COUNT )); then
  echo "FortiGate Iran streaming feed: too few domains ($count); stopping" >&2
  exit 1
fi

if [[ -f "$DOMAIN_FEED" ]]; then
  grep -v '^\*\.' "$DOMAIN_FEED" | sed '/^[[:space:]]*$/d' | LC_ALL=C sort -u > "$TMP_DIR/previous-domains.txt"
  previous_count="$(wc -l < "$TMP_DIR/previous-domains.txt" | tr -d ' ')"
  if (( previous_count > 0 && count * 100 < previous_count * (100 - MAX_DROP_PERCENT) )); then
    echo "Domain count dropped from $previous_count to $count by more than ${MAX_DROP_PERCENT}%; refusing to publish" >&2
    exit 1
  fi
fi

: > "$TMP_DIR/object-names.txt"
while IFS= read -r domain; do
  name="IRSTR-$(normalize_name "$domain")"
  printf '%s\n%s-WILD\n' "$name" "$name" >> "$TMP_DIR/object-names.txt"
done < "$TMP_DIR/domains.txt"

if duplicates="$(LC_ALL=C sort "$TMP_DIR/object-names.txt" | uniq -d)" && [[ -n "$duplicates" ]]; then
  echo "FortiGate object-name collision detected:" >&2
  printf '%s\n' "$duplicates" >&2
  exit 1
fi

{
  while IFS= read -r domain; do
    printf '%s\n*.%s\n' "$domain" "$domain"
  done < "$TMP_DIR/domains.txt"
} > "$TMP_DIR/domain-feed.txt"

{
  echo '# managed-by=mohavise-fortigate-iran-streaming-route-list'
  echo '# project=fortigate-iran-streaming-route-list'
  echo '# source=mikrotik-iran-streaming-route-list'
  echo '# output=fortigate-fqdn-address-objects'
  echo '# do-not-edit-manually'
  echo
  echo 'config firewall address'
  while IFS= read -r domain; do
    name="IRSTR-$(normalize_name "$domain")"
    wild_name="${name}-WILD"
    printf '    edit "%s"\n' "$name"
    echo '        set type fqdn'
    printf '        set fqdn "%s"\n' "$domain"
    echo '    next'
    printf '    edit "%s"\n' "$wild_name"
    echo '        set type fqdn'
    printf '        set fqdn "*.%s"\n' "$domain"
    echo '    next'
  done < "$TMP_DIR/domains.txt"
  echo 'end'
  echo
  echo 'config firewall addrgrp'
  echo '    edit "GRP-IRAN-STREAMING"'
  printf '        set member'
  while IFS= read -r domain; do
    name="IRSTR-$(normalize_name "$domain")"
    printf ' "%s" "%s-WILD"' "$name" "$name"
  done < "$TMP_DIR/domains.txt"
  echo
  echo '    next'
  echo 'end'
} > "$TMP_DIR/address-objects.conf"

feed_count="$(wc -l < "$TMP_DIR/domain-feed.txt" | tr -d ' ')"
object_count="$(grep -c '^    edit "IRSTR-' "$TMP_DIR/address-objects.conf" || true)"
member_count="$(grep '^        set member' "$TMP_DIR/address-objects.conf" | grep -o '"IRSTR-[^"]*"' | wc -l | tr -d ' ')"
expected_count=$((count * 2))

if (( feed_count != expected_count || object_count != expected_count || member_count != expected_count )); then
  echo "Generated-output count validation failed" >&2
  exit 1
fi

if grep -q 'set type wildcard-fqdn\|set wildcard-fqdn' "$TMP_DIR/address-objects.conf"; then
  echo "Unsupported wildcard address syntax detected" >&2
  exit 1
fi

cmp -s "$TMP_DIR/domain-feed.txt" "$DOMAIN_FEED" || cp "$TMP_DIR/domain-feed.txt" "$DOMAIN_FEED"
cmp -s "$TMP_DIR/address-objects.conf" "$OBJECTS_FILE" || cp "$TMP_DIR/address-objects.conf" "$OBJECTS_FILE"

echo "source domains: $count"
echo "feed entries: $feed_count"
echo "address objects: $object_count"
echo "domain feed: $DOMAIN_FEED"
echo "address objects file: $OBJECTS_FILE"
