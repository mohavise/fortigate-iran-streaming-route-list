# FortiGate Iran Streaming Route List

FortiGate-friendly domain feed for Iranian streaming, VOD, live TV, and media services.

This repository is the **FortiGate child/slave repo** of:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

The master repository maintains the trusted Iranian streaming service database. This repository converts that shared data into a clean FortiGate-friendly feed.

```text
mikrotik-iran-streaming-route-list
        ↓
source service domains
        ↓
fortigate-iran-streaming-route-list
        ↓
FortiGate external domain feed
```

## Purpose

This project publishes a plain domain list for Iranian video, VOD, live TV, and streaming platforms. The list can be used on FortiGate as an external domain resource/feed in FortiOS features that support domain feeds, such as DNS filtering, web filtering, or related security profiles depending on your FortiOS version and design.

This repository is designed for environments where selected Iranian streaming services should be identified separately from normal internet traffic.

Common use cases:

- identify Iranian streaming domains on FortiGate
- use the same service database as the MikroTik route-list project
- keep FortiGate feeds updated automatically from GitHub
- separate streaming traffic for policy, monitoring, filtering, or routing-related workflows
- maintain one clean downstream FortiGate output instead of manually editing firewall objects

## Important Design

This repository is currently a **domain feed**, not an IP/CIDR feed.

```text
service domains → FortiGate-friendly domain list
```

It does **not** currently publish IP address lists because most streaming services use CDNs, shared hosting, and changing IP addresses. Domains are safer and easier to maintain for this use case.

If you need a real FortiGate IP address feed later, it should be created as a separate output file:

```text
fortigate-iran-streaming-addresses.txt
```

Do not mix domains and IP addresses in the same feed unless the FortiGate feature you are using explicitly supports that mixed format.

## Output File

Final FortiGate feed:

```text
fortigate-iran-streaming-domains.txt
```

Raw URL:

```text
https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
```

Expected format:

```text
filimo.com
aparat.com
namava.ir
telewebion.com
```

The output file should be plain text, one domain per line, with no RouterOS syntax and no FortiGate CLI syntax inside the feed.

## Master Source

This repo should not maintain its own independent service database.

The source of truth is the MikroTik Iran Streaming Route List repository:

```text
https://github.com/mohavise/mikrotik-iran-streaming-route-list
```

Source domain file:

```text
https://raw.githubusercontent.com/mohavise/mikrotik-iran-streaming-route-list/main/iran-streaming-domains.txt
```

Build logic:

```text
master iran-streaming-domains.txt
        ↓
normalize / clean / sort
        ↓
fortigate-iran-streaming-domains.txt
```

## Included Services

The upstream service database starts with popular Iranian video and streaming platforms, including:

- Filimo
- Aparat
- Aparat Kids
- Namava
- Telewebion
- Anten
- Lenz
- Tamasha
- Namasha
- Shabakema
- IMVBox
- IRIB / iFilm / TV-related services
- related media/CDN domains such as Saba Idea and Saba Vision

The exact final list is generated from the master repository.

## How To Use On FortiGate

There are two common ways to use this feed:

1. Add it from the FortiGate GUI as an external domain resource.
2. Add it from FortiGate CLI under `config system external-resource`.

The exact menu names can be different between FortiOS versions, but the idea is the same: FortiGate downloads the raw GitHub text file and refreshes it automatically.

## Method 1 — FortiGate GUI

Open FortiGate GUI and go to the external resource area. Depending on FortiOS version, it may be under a menu such as:

```text
Security Fabric → External Connectors
```

or:

```text
Security Fabric → External Resources
```

Create a new external resource.

Recommended values:

```text
Name: mohavise-iran-streaming-domains
Type: Domain List / Domain Feed
URL:  https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt
Refresh interval: 1440 minutes
```

Then save the object and check that FortiGate can download the feed successfully.

After the feed is created, attach it to the FortiGate feature you want to use. The correct place depends on your FortiOS version and design. Common places are DNS filter profiles, web filter profiles, or other security-profile/external-resource features that support domain feeds.

## Method 2 — FortiGate CLI

Example CLI configuration:

```fortios
config system external-resource
    edit "mohavise-iran-streaming-domains"
        set type domain
        set resource "https://raw.githubusercontent.com/mohavise/fortigate-iran-streaming-route-list/main/fortigate-iran-streaming-domains.txt"
        set refresh-rate 1440
    next
end
```

This creates an external domain feed named:

```text
mohavise-iran-streaming-domains
```

Refresh rate:

```text
1440 minutes = 1 day
```

## Recommended FortiGate Workflow

Recommended workflow:

```text
1. Add the raw GitHub URL as an external domain resource.
2. Confirm FortiGate downloads the feed successfully.
3. Attach the external resource to the required DNS/web/security profile.
4. Apply that profile to the firewall policy used by clients.
5. Monitor logs to confirm matching traffic.
```

## Important FortiGate Notes

A domain feed is not the same as an IP address object.

Domain feed:

```text
filimo.com
aparat.com
namava.ir
```

IP address feed:

```text
185.0.0.0/24
203.0.113.10
```

For firewall policy routing, FortiGate routing decisions are usually IP based. A domain feed alone may not be enough for direct route selection unless your FortiOS design or feature converts or applies those domains in the path you need.

For filtering, identification, and DNS/web profile matching, a domain feed is usually the correct format.

If your goal is strict FortiGate policy-based routing by destination, the next professional step is to add a separate IP/CIDR output if reliable IP sources exist.

## Testing

After adding the external resource, test in this order:

```text
1. Confirm FortiGate can reach raw.githubusercontent.com.
2. Confirm the external resource status is successful.
3. Open a client behind FortiGate.
4. Browse to a service such as filimo.com or aparat.com.
5. Check FortiGate logs for matching DNS/web/security profile events.
6. Confirm the correct policy/profile is applied to the client traffic.
```

Useful test domains:

```text
filimo.com
aparat.com
namava.ir
telewebion.com
```

## Troubleshooting

### FortiGate cannot download the list

Check internet access from FortiGate to GitHub raw content:

```text
raw.githubusercontent.com
```

Also check DNS, SSL inspection, upstream proxy, and firewall policy for FortiGate management traffic.

### The feed downloads but nothing matches

Check these items:

```text
- Is the external resource attached to the correct profile?
- Is that profile applied to the correct firewall policy?
- Are clients using DNS through FortiGate or a path visible to FortiGate?
- Are logs enabled on the policy/profile?
- Is the feature you selected designed to use domain feeds?
```

### The feed works in DNS/web filtering but not in routing

This is expected in many designs.

Domain feeds identify names. Routing is usually performed on destination IPs. If routing by service is required, you may need FortiGate features that support domain-based matching in your FortiOS version, or a separate IP address feed.

## Update Schedule

Recommended schedule:

```text
Master MikroTik repo updates first.
FortiGate child repo updates after master.
FortiGate refreshes the external resource daily.
```

Suggested GitHub Actions timing for this child repo:

```text
00:00 UTC daily
```

Suggested FortiGate refresh rate:

```text
1440 minutes
```

## File Structure

Recommended minimal structure:

```text
README.md
fortigate-iran-streaming-domains.txt
scripts/build-fortigate-iran-streaming.sh
.github/workflows/update.yml
```

Future optional files:

```text
fortigate-iran-streaming-addresses.txt
services/iran-streaming/metadata.json
```

## Build Manually

After the build script is added, manual build should look like this:

```bash
./scripts/build-fortigate-iran-streaming.sh
```

Expected build flow:

```text
download master domain list
normalize domains
remove empty lines and comments
sort unique
write fortigate-iran-streaming-domains.txt
```

## Markers

Generated files should use this repository marker when comments are allowed:

```text
managed-by=mohavise-fortigate-iran-streaming-route-list
project=fortigate-iran-streaming-route-list
source=mikrotik-iran-streaming-route-list
```

The final FortiGate feed itself should normally stay clean and contain only domains, because FortiGate feed parsers usually expect simple one-item-per-line content.

## License

MIT
