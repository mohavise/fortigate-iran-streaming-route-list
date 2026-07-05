# FortiGate Iran Streaming Route List

FortiGate-friendly outputs for Iranian streaming, VOD, live TV, and media services.

```text
mikrotik-iran-streaming-route-list  →  fortigate-iran-streaming-route-list
master/source repo                  →  FortiGate child/slave outputs
```

## Purpose

This repository converts the shared Iranian streaming domain database from the MikroTik master repository into FortiGate-ready outputs.

Master source:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

This repo is useful when you want FortiGate to recognize Iranian streaming services by domain/FQDN and then use them in DNS filtering, web filtering, security profiles, or firewall policies.

## Final outputs

```text
fortigate-iran-streaming-domains.txt
fortigate-iran-streaming-address-objects.conf
```

Raw URLs:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-address-objects.conf
```

## Output summary

| File | Purpose | FortiGate use |
| --- | --- | --- |
| `fortigate-iran-streaming-domains.txt` | Root + wildcard domain feed | External Resource / DNS Filter / Web Filter |
| `fortigate-iran-streaming-address-objects.conf` | FQDN objects + address group | Firewall policy `dstaddr` / address group |

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
master iran-streaming domain database
        ↓
normalize / clean / sort
        ↓
FortiGate domain feed: root + wildcard entries
FortiGate FQDN objects: root + wildcard objects + group
```

## Why root + wildcard?

Root-only is not enough for modern streaming services because traffic often uses many subdomains.

```text
filimo.com      = root domain
*.filimo.com    = subdomains such as www/api/cdn/video hosts
```

Wildcard-only is also not ideal because the root domain and subdomains should be handled clearly.

Best coverage:

```text
filimo.com
*.filimo.com
aparat.com
*.aparat.com
namava.ir
*.namava.ir
```

## Output 1 — External domain feed

File:

```text
fortigate-iran-streaming-domains.txt
```

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
```

Example content:

```text
filimo.com
*.filimo.com
aparat.com
*.aparat.com
namava.ir
*.namava.ir
```

Use this when FortiGate needs a domain list from URL.

Recommended values:

```text
Name: mohavise-iran-streaming-domains
Type: Domain List / Domain Feed
URL:  https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
Refresh: 1440 minutes
```

Generic CLI example:

```fortios
config system external-resource
    edit "mohavise-iran-streaming-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt"
        set refresh-rate 1440
    next
end
```

Attach the external resource to the FortiGate feature that supports domain feeds in your FortiOS version, such as DNS filter, web filter, or another security/security-profile feature.

## FortiGate feed configuration manual

Use this section when you want to configure the auto-refresh domain feed on FortiGate.

### Step 1 — Confirm FortiGate internet and DNS

FortiGate must be able to resolve and reach GitHub raw URLs.

```fortios
execute ping raw.githubusercontent.com
```

If this fails, fix FortiGate DNS, routing, policy, SSL inspection, or upstream proxy before adding the feed.

### Step 2 — Create the external resource

CLI:

```fortios
config system external-resource
    edit "mohavise-iran-streaming-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt"
        set refresh-rate 1440
    next
end
```

GUI path may vary by FortiOS version, but the idea is:

```text
Security Fabric / External Connectors / External Resource
        ↓
Create New
        ↓
Domain List / Domain Feed
        ↓
Paste raw GitHub URL
        ↓
Set refresh interval
```

Recommended values:

```text
Name: mohavise-iran-streaming-domains
Type: Domain List / Domain Feed
URL:  https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
Refresh: 1440 minutes
```

### Step 3 — Verify the feed downloads

Check the external resource status in the GUI.

If your FortiOS supports CLI diagnostics for external resources, check that the object is present and updated.

```fortios
show system external-resource
```

Expected idea:

```text
mohavise-iran-streaming-domains exists
resource URL is correct
refresh-rate is configured
feed status is successful in GUI
```

### Step 4 — Attach the feed to the correct FortiGate feature

The external domain feed is only useful after it is attached to a feature or profile that supports domain feeds.

Common use cases:

```text
DNS Filter profile
Web Filter profile
Security profile / external domain resource feature
```

Then attach that profile to the correct firewall policy.

Example policy idea:

```text
LAN users policy
        ↓
DNS/Web/Security profile using mohavise-iran-streaming-domains
        ↓
FortiGate checks matched streaming domains
```

### Step 5 — Test with real domains

Test known entries:

```text
filimo.com
www.filimo.com
aparat.com
www.aparat.com
namava.ir
www.namava.ir
telewebion.com
www.telewebion.com
```

Then check FortiGate logs for DNS filter, web filter, or policy/profile matches.

### Important note about wildcard feed entries

This feed contains both root and wildcard entries:

```text
filimo.com
*.filimo.com
```

Some FortiGate features and versions may handle wildcard entries differently. If your FortiGate feature does not match wildcard feed entries as expected, use the second output file instead:

```text
fortigate-iran-streaming-address-objects.conf
```

That file creates FortiGate-native FQDN and wildcard FQDN address objects.

## Output 2 — FQDN address objects and group

File:

```text
fortigate-iran-streaming-address-objects.conf
```

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

Example FortiGate config generated by this repo:

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

config firewall addrgrp
    edit "GRP-IRAN-STREAMING"
        set member "IRSTR-FILIMO-COM" "IRSTR-FILIMO-COM-WILD"
    next
end
```

Use the group in a firewall policy:

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

Adjust policy ID, interfaces, NAT, routing, service, and inspection profiles to your own FortiGate design.

## Address-object import manual

Use this section when you want a real FortiGate firewall address group called:

```text
GRP-IRAN-STREAMING
```

### Step 1 — Download the generated config

Open this raw URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-address-objects.conf
```

Copy all content.

### Step 2 — Import into FortiGate CLI

Paste the full config into FortiGate CLI.

It will create:

```text
Root FQDN objects
Wildcard FQDN objects
GRP-IRAN-STREAMING address group
```

### Step 3 — Use the group in firewall policy

Use the generated group as destination address:

```fortios
set dstaddr "GRP-IRAN-STREAMING"
```

Example:

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

### Step 4 — Verify FQDN learning

Useful commands:

```fortios
diagnose firewall fqdn list
```

or depending on FortiOS version:

```fortios
diagnose firewall fqdn list-all
```

## Which output should I use?

Simple rule:

```text
Need external feed/profile matching?  Use fortigate-iran-streaming-domains.txt
Need firewall dstaddr group?          Use fortigate-iran-streaming-address-objects.conf
```

Recommended practical design:

```text
Use the domain feed for FortiGate features that can auto-refresh from URL.
Use the address-object config when you need GRP-IRAN-STREAMING in firewall policy.
```

## Auto update behavior

GitHub Actions updates both output files every day:

```text
fortigate-iran-streaming-domains.txt
fortigate-iran-streaming-address-objects.conf
```

Important difference:

```text
Domain feed:
  FortiGate can auto-refresh from the raw URL.

FQDN address objects:
  Existing objects can resolve/update their IPs by FortiGate DNS.
  New or removed domain objects need the updated .conf file to be imported again.
```

So the real behavior is:

```text
New domain added in GitHub database
        ↓
GitHub Action regenerates both outputs
        ↓
Domain feed refreshes automatically on FortiGate
        ↓
Address-object config must be imported again if new objects are needed
```

## DNS learning requirement for wildcard FQDN objects

For wildcard FQDN address objects to be useful, FortiGate must be able to learn DNS answers.

Best practice:

```text
Client DNS traffic should pass through FortiGate.
Avoid clients bypassing DNS visibility with DoH/DoT unless your FortiGate design inspects/controls it.
```

If FortiGate cannot see DNS responses, wildcard FQDN objects may not learn the related IP addresses correctly.

Useful check commands:

```fortios
diagnose firewall fqdn list
```

or depending on FortiOS version:

```fortios
diagnose firewall fqdn list-all
```

## Test checklist

```text
1. Confirm FortiGate can reach raw.githubusercontent.com.
2. For domain feed, confirm the external resource downloads successfully.
3. Attach the feed to the correct DNS/Web/Security profile and policy.
4. For address objects, import the .conf file and confirm GRP-IRAN-STREAMING exists.
5. Confirm client DNS traffic passes through FortiGate.
6. Browse/test domains such as filimo.com, aparat.com, namava.ir, telewebion.com.
7. Check FortiGate logs and FQDN object resolution.
```

## Troubleshooting

If the domain feed does not download, check FortiGate DNS, internet access, SSL inspection, upstream proxy, and access to `raw.githubusercontent.com`.

If the domain feed downloads but does not match, check that the external resource is attached to the correct FortiGate feature/profile and that the profile is applied to the correct firewall policy.

If the address group exists but traffic does not match, check that FortiGate has resolved the FQDN objects and that `GRP-IRAN-STREAMING` is used in the correct firewall policy.

If clients use encrypted DNS and FortiGate cannot inspect it, wildcard FQDN learning can fail.

If filtering works but routing does not, remember that domains and FQDN objects are not the same as a real IP/CIDR routing table. CDN/shared IP behavior can affect precision.

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
4. Keep FQDN object config with root + wildcard objects and GRP-IRAN-STREAMING.
5. Add real IP/CIDR feed only if reliable sources exist.
6. Add FortiGate auto-import workflow later only after safe testing.
```

## License

MIT
