# FortiGate Iran Streaming Route List

FortiGate-friendly outputs for Iranian streaming, VOD, live TV, and media services.

```text
mikrotik-iran-streaming-route-list  →  fortigate-iran-streaming-route-list
master/source repo                  →  FortiGate child/slave outputs
```

## Purpose

This repository converts the shared Iranian streaming domain list from the MikroTik master repository into FortiGate-friendly outputs.

Master source:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

Final outputs:

```text
fortigate-iran-streaming-domains.txt
fortigate-iran-streaming-address-objects.conf
```

## Design

This repo is intentionally compact:

```text
README.md
LICENSE
fortigate-iran-streaming-domains.txt
fortigate-iran-streaming-address-objects.conf
scripts/build-fortigate-iran-streaming.sh
.github/workflows/update.yml
```

Build flow:

```text
master iran-streaming-domains.txt
        ↓
normalize / clean / sort
        ↓
FortiGate domain feed: root + wildcard entries
FortiGate FQDN address objects: root + wildcard objects + group
```

## Output 1 — External domain feed

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
```

Use this as a FortiGate external domain resource/feed.

The feed includes both the root domain and wildcard domain because root-only is not enough for services with many subdomains.

Example:

```text
filimo.com
*.filimo.com
aparat.com
*.aparat.com
namava.ir
*.namava.ir
```

Meaning:

```text
filimo.com    = root domain
*.filimo.com  = subdomains
```

## Output 2 — FQDN address objects and group

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-address-objects.conf
```

This file creates FortiGate FQDN address objects and one address group:

```text
GRP-IRAN-STREAMING
```

For each domain, it creates two objects:

```text
IRSTR-FILIMO-COM       → filimo.com
IRSTR-FILIMO-COM-WILD  → *.filimo.com
```

Why both?

```text
filimo.com    = root domain
*.filimo.com  = subdomains
```

## How to use on FortiGate

### Method A — External domain feed

Create an external domain resource/feed.

```text
Name: mohavise-iran-streaming-domains
Type: Domain List / Domain Feed
URL:  https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
Refresh: 1440 minutes
```

Use this for DNS filter, web filter, or other FortiGate features that support domain feeds.

### Method B — Address objects and group

Download/import this file into FortiGate CLI:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-address-objects.conf
```

It creates:

```text
config firewall address
    root FQDN objects
    wildcard FQDN objects
end

config firewall addrgrp
    GRP-IRAN-STREAMING
end
```

Then you can use this group in a firewall policy:

```fortios
config firewall policy
    edit 100
        set name "Iran Streaming"
        set srcintf "LAN"
        set dstintf "WAN"
        set srcaddr "all"
        set dstaddr "GRP-IRAN-STREAMING"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
    next
end
```

Adjust interfaces, policy ID, NAT, service, and routing to your own design.

## Auto update behavior

GitHub Actions updates both output files every day:

```text
fortigate-iran-streaming-domains.txt
fortigate-iran-streaming-address-objects.conf
```

FortiGate external domain feed can refresh automatically from the raw URL.

FortiGate FQDN address objects are different:

```text
Existing FQDN objects resolve/update their IPs automatically by FortiGate DNS.
New/removed domains need the .conf file to be imported again.
```

So:

```text
Domain feed = FortiGate can auto-refresh from URL
Address objects/group = FortiGate must import updated CLI config when domain list changes
```

## Test

```text
1. Confirm FortiGate can reach raw.githubusercontent.com.
2. For domain feed: confirm external resource downloads successfully.
3. For address objects: import the .conf file and check GRP-IRAN-STREAMING.
4. Test domains such as filimo.com, aparat.com, namava.ir, telewebion.com.
5. Check FortiGate logs and FQDN object resolution.
```

## Troubleshooting

If the feed does not download, check FortiGate DNS, internet access, SSL inspection, upstream proxy, and access to `raw.githubusercontent.com`.

If the address group exists but traffic does not match, check that FortiGate has resolved the FQDN objects and that the group is used in the correct firewall policy.

If filtering works but routing does not, remember that domain feeds identify names; routing is normally IP based. FQDN address objects can help, but CDN/shared IP behavior can still affect precision.

## Markers

Repository sign:

```text
managed-by=mohavise-fortigate-iran-streaming-route-list
project=fortigate-iran-streaming-route-list
source=mikrotik-iran-streaming-route-list
```

## Future vision

```text
1. Keep MikroTik repo as master source.
2. Keep this repo as FortiGate child output.
3. Keep external domain feed with root + wildcard entries.
4. Keep FQDN object config with root + wildcard objects.
5. Add real IP/CIDR feed only if reliable sources exist.
```

## License

MIT
