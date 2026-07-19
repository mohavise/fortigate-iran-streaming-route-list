# FortiGate Iran Streaming Route List

FortiGate-ready domain outputs for Iranian streaming, VOD, live TV, and media services.

```text
mikrotik-iran-streaming-route-list
        ↓
fortigate-iran-streaming-route-list
        ↓
FortiGate external domain feed or firewall address objects
```

The shared source database is maintained in:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

## Outputs

| File | Purpose |
| --- | --- |
| `fortigate-iran-streaming-domains.txt` | Root and wildcard domain feed for a FortiGate external resource |
| `fortigate-iran-streaming-address-objects.conf` | Root and wildcard FQDN firewall address objects with `GRP-IRAN-STREAMING` |

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

Attach the external resource to the DNS-filter, web-filter, or another feature that supports domain external resources in your FortiOS version.

## Native Firewall Address Objects

Raw configuration URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-address-objects.conf
```

For each domain, the generated configuration creates a normal FQDN object for the root and another FQDN object whose value begins with `*.`:

```fortios
config firewall address
    edit "IRSTR-FILIMO-COM"
        set type fqdn
        set fqdn "filimo.com"
    next
    edit "IRSTR-FILIMO-COM-WILD"
        set type fqdn
        set fqdn "*.filimo.com"
    next
end
```

For firewall address objects, do not use this syntax:

```fortios
set type wildcard-fqdn
set wildcard-fqdn "*.filimo.com"
```

That is not the documented syntax under `config firewall address`. Fortinet documents wildcard firewall address objects as `set type fqdn` with the wildcard stored in `set fqdn`.

All generated objects are included in:

```text
GRP-IRAN-STREAMING
```

Use the group as a destination address when a firewall policy needs the native objects:

```fortios
set dstaddr "GRP-IRAN-STREAMING"
```

## Wildcard FQDN Behavior

A wildcard FQDN object does not proactively resolve every possible subdomain. It starts empty and learns IP addresses from matching DNS responses that traverse the FortiGate.

Therefore:

```text
Client DNS queries and responses must traverse the correct FortiGate VDOM.
DNS session-helper/inspection must be available.
DoH normally prevents wildcard learning because FortiGate cannot read the DNS response.
Learned IPs remain until their DNS TTL expires.
```

The root object is kept separately because `*.filimo.com` covers subdomains but should not be assumed to cover `filimo.com` itself.

## Build

```bash
./scripts/build-fortigate-iran-streaming.sh
```

The builder:

```text
Downloads the source through HTTPS with retries and timeouts
→ strictly validates every domain
→ rejects IP addresses and malformed labels
→ rejects a source drop greater than 20%
→ detects duplicate FortiGate object names
→ generates root and wildcard feed entries
→ generates documented FortiGate FQDN address syntax
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

## Important

FortiGate wildcard FQDN firewall-policy support was added in modern FortiOS releases. Verify the behavior against the exact FortiOS version installed on your device, especially on older FortiGate models.
