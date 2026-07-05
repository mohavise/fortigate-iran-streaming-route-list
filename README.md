# FortiGate Iran Streaming Route List

FortiGate-friendly domain feed for Iranian streaming, VOD, live TV, and media services.

```text
mikrotik-iran-streaming-route-list  →  fortigate-iran-streaming-route-list
master/source repo                  →  FortiGate child/slave feed
```

## Purpose

This repository converts the shared Iranian streaming domain list from the MikroTik master repository into a clean FortiGate-friendly domain feed.

Master source:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

Final FortiGate feed:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
```

## Design

This repo is intentionally compact:

```text
README.md
LICENSE
fortigate-iran-streaming-domains.txt
scripts/build-fortigate-iran-streaming.sh
.github/workflows/update.yml
```

Build flow:

```text
master iran-streaming-domains.txt
        ↓
normalize / clean / sort
        ↓
fortigate-iran-streaming-domains.txt
```

## Important

This is a **domain feed**, not an IP/CIDR feed.

```text
Domain feed  → filimo.com, aparat.com, namava.ir
IP feed      → 1.2.3.4, 1.2.3.0/24
```

Do not mix domains and IPs in one FortiGate external resource unless your FortiOS feature explicitly supports that format.

## How to use on FortiGate

### GUI

Create an external domain resource/feed.

Recommended values:

```text
Name: mohavise-iran-streaming-domains
Type: Domain List / Domain Feed
URL:  https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
Refresh: 1440 minutes
```

Then attach the feed to the FortiGate feature that supports domain feeds in your design, such as DNS filtering, web filtering, or another security profile depending on FortiOS version.

### CLI

```fortios
config system external-resource
    edit "mohavise-iran-streaming-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt"
        set refresh-rate 1440
    next
end
```

## Test

```text
1. Confirm FortiGate can reach raw.githubusercontent.com.
2. Confirm the external resource downloads successfully.
3. Attach the feed to the correct FortiGate profile/policy.
4. Test domains such as filimo.com, aparat.com, namava.ir, telewebion.com.
5. Check FortiGate logs for matches.
```

## Troubleshooting

If the feed does not download, check FortiGate DNS, internet access, SSL inspection, upstream proxy, and access to `raw.githubusercontent.com`.

If the feed downloads but does not match traffic, check that the external resource is attached to the correct profile and that the profile is applied to the correct firewall policy.

If filtering works but routing does not, that is usually expected. Domain feeds identify names; routing is normally IP based. A future IP/CIDR feed can be added separately if reliable address sources exist.

## Markers

Repository sign:

```text
managed-by=mohavise-fortigate-iran-streaming-route-list
project=fortigate-iran-streaming-route-list
source=mikrotik-iran-streaming-route-list
```

The final FortiGate feed stays plain and contains only domains.

## Future vision

Planned direction:

```text
1. Keep MikroTik repo as master source.
2. Keep this repo as FortiGate domain-feed child.
3. Add FortiGate IP/CIDR output later only if reliable sources exist.
4. Keep all final device-facing files in repo root.
5. Keep GitHub Actions automated and commit only when output changes.
```

## License

MIT
