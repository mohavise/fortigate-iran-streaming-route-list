# FortiGate Iran Streaming Route List

FortiGate-ready domain outputs for Iranian streaming, VOD, live TV, and media services.

```text
mikrotik-iran-streaming-route-list
        ↓
fortigate-iran-streaming-route-list
        ↓
FortiGate external domain feed or address objects
```

The shared source database is maintained in:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

## Outputs

| File | Purpose |
| --- | --- |
| `fortigate-iran-streaming-domains.txt` | Root and wildcard domain feed for a FortiGate external resource |
| `fortigate-iran-streaming-address-objects.conf` | Native FQDN and wildcard-FQDN objects with `GRP-IRAN-STREAMING` |

## External Domain Feed

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
```

The feed contains two entries per source domain:

```text
filimo.com
*.filimo.com
```

Example external resource:

```fortios
config system external-resource
    edit "mohavise-iran-streaming-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt"
        set refresh-rate 1440
    next
end
```

Attach the external resource to the DNS-filter, web-filter, or other supported security-profile feature used by your FortiOS version.

## Native Address Objects

Raw configuration URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-address-objects.conf
```

For each domain, the generated configuration creates:

```fortios
config firewall address
    edit "IRSTR-FILIMO-COM"
        set type fqdn
        set fqdn "filimo.com"
    next
    edit "IRSTR-FILIMO-COM-WILD"
        set type wildcard-fqdn
        set wildcard-fqdn "*.filimo.com"
    next
end
```

All generated objects are included in:

```text
GRP-IRAN-STREAMING
```

Use the group as a destination address when a firewall policy needs the native FortiGate objects:

```fortios
set dstaddr "GRP-IRAN-STREAMING"
```

The external resource refreshes automatically. The native object configuration must be imported again when domains are added or removed.

## Build

```bash
./scripts/build-fortigate-iran-streaming.sh
```

The builder:

```text
Downloads the source through HTTPS with retries and timeouts
→ normalizes and strictly validates every domain
→ rejects IP addresses and malformed labels
→ rejects a source drop greater than 20%
→ detects duplicate FortiGate object names
→ generates root and wildcard feed entries
→ generates fqdn and wildcard-fqdn objects
→ verifies feed, object, and group-member counts
→ replaces outputs only after all checks pass
```

Environment overrides:

```text
SOURCE_URL
DOMAIN_FEED
OBJECTS_FILE
MIN_DOMAIN_COUNT
MAX_DROP_PERCENT
```

## GitHub Automation

Workflow:

```text
.github/workflows/update.yml
```

It runs daily at `00:00 UTC` and can also be started manually. Overlapping runs are serialized, the job has a 15-minute timeout, and unchanged outputs are not committed.

## Files

| File | Purpose |
| --- | --- |
| `scripts/build-fortigate-iran-streaming.sh` | Builds and validates both outputs |
| `.github/workflows/update.yml` | Daily generation workflow |
| `fortigate-iran-streaming-domains.txt` | Public domain-feed endpoint |
| `fortigate-iran-streaming-address-objects.conf` | Importable FortiGate configuration |

## Important

Do not use the generated address group as the only routing mechanism without verifying how FQDN learning behaves in your FortiOS version and network design. FortiGate must be able to resolve and learn the domains used by the generated objects.
