---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
_class: title-slide
---

# Advanced DNS/DNSSEC Workshop
## Module 11: DNS Monitoring, Incident Response, and Performance Optimisation

**Instructor:** Terry Sweetser — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Module Overview

---
<!-- _class: dense -->
## Learning Objectives

By the end of this module, participants will be able to:

- **Choose** what to watch on an authoritative service and on a resolver: the four golden signals, serials on every server, the delegation at the parent, signature and certificate lifetimes
- **Read** BIND's counters (statistics channel, `rndc stats`), turn them into rates, and capture traffic with dnstap
- **Deploy** Prometheus with bind_exporter and blackbox probes, write alert rules, and test that an alert fires and clears
- **Measure** a resolver under a capped load and explain the result from its counters (cache hit ratio, recursion, limits)
- **Respond** to an incident: detect, gather evidence in order, fix, verify and write the record
- **Plan** recovery: RTO and RPO for DNS, what to back up, how long each layer keeps answering without you

---
<!-- _class: dense -->
## Where Day 6 Starts

```text
 VM 1  192.0.2.30  BIND authoritative: teamNN.example (lab policy, Module 7), manualNN.example
                   (signed by hand, Lab 7.1); recursion no, rate limiting (Module 6)
 VM 2  192.0.2.10  BIND validating resolver: static-stub for example., trust anchor (Module 7),
                   DoT 853 and DoH 443 with the team certificate (Module 8)
 registry 192.0.2.53   example.: your delegation and DS (Modules 7 and 9)
```

- Modules 1-7 left pointers to this module (Module 8's 30-day certificate is the reason for the certificate probe): serials on every server, the parent's delegation, counters, dnstap, signature expiry, stale answers, "the same checks every minute"
- Module 10 has no lab on these VMs yet; if it gets one, it must leave them as they are. Today's labs undo their changes: Module 12 starts from the state above
- Not here: abuse detection and filtering (Module 12), attacks and RRL design (Module 6)

<!--
Module 5's troubleshooting section ends "Monitoring (Module 11) runs the same checks every minute; this section is what you do by hand when it alarms". This module builds those checks, and the incident drill uses them. The VM state is the rehearsal's stand-in for Modules 6-9 (labs/module11/test/rehearse.sh); if Module 10 is given a lab on these VMs, its end state must be checked against this slide.
-->

---
<!-- _class: dense table-compact -->
## What Changed Recently

| Then | Now (as of 28 October 2026) |
|---|---|
| NIST SP 800-61 Rev. 2 (2012): its own four-phase incident life cycle | SP 800-61 Rev. 3 (April 2025) organises incident response by the CSF 2.0 Functions; Rev. 2 withdrawn on 3 April 2025 |
| "Lame delegation" from RFC 1912 (1996) | RFC 9499 (BCP 219, 2024) quotes it and adds "there is no consensus on what a lame delegation is" |
| Prometheus 2.53 LTS | Debian 13 ships 2.53.3; upstream support for 2.53 ended 31 July 2025 (current LTS: 3.13). Grafana is not in Debian |
| dnsperf and resperf on GitHub | Moved to Codeberg (DNS-OARC); 2.16.0 released 5 August 2026; Debian 13 has 2.14.0 |
| Outside vantage points | RIPE Atlas: 15,295 connected probes (its API, 27 October 2026 UTC); DNS measurements cost credits |

<!--
Sources fetched 27-28 October 2026 (plan/m11_notes.md): csrc.nist.gov pages for SP 800-61 Rev. 3 ("Date Published: April 2025") and Rev. 2 ("Withdrawn on April 03, 2025"); RFC 9499 §2 "Lame delegation"; prometheus.io release-cycle page ("Prometheus 2.53 | 2024-06-16 | 2025-07-31 | End of life"); Debian 13 apt-cache policy (prometheus 2.53.3+ds1-2, dnsperf 2.14.0-5); the DNS-OARC page and Codeberg release list (dnsperf 2.16.0, 5 August 2026); RIPE Atlas API /api/v2/probes/?status=1 ("count": 15295). Debian supports its 2.53 package for Debian 13's life; the upstream date matters only if you install upstream builds.
-->

---
<!-- _class: dense compact-list tight -->
## Agenda (90 min Theory)

1. Where Day 6 starts and what changed (5m)
2. What to watch (15m)
3. Where the numbers come from (13m)
4. Collecting, alerting, looking from outside (15m)
5. Performance and capacity (14m)
6. Incident response (16m)
7. Continuity and recovery (12m)

## Agenda (90 min Lab)

1. Lab 11.1 Counters, rates and a capture (20m)
2. Lab 11.2 Prometheus, exporters and alerts (25m)
3. Lab 11.3 Checks across servers and the parent (10m)
4. Lab 11.4 Incident drill and clean-up (35m)

<!--
Day 6 Session 1 has no knowledge-check slot (Program Facts: knowledge checks take the end of Session 3). The 90 minutes are all content. Practical Assessment 6A is assessed from Labs 11.1-11.4 and takes no extra time.
-->

---
<!-- _class: section-divider -->
# 1 · What to Watch

---
<!-- _class: dense -->
## Why DNS Fails Quietly

- **Partial failure is the normal case:** one of three servers, one anycast site, one catchment, only validating resolvers, only TCP. Resolvers retry elsewhere, so users see slowness before they see errors
- **Caches hide failures, then reveal them:** an outage starts when TTLs run out, not when the server stops; a fix arrives the same way (Lab 11.4 measures both)
- **The data can be wrong while every server is up:** an old serial on one server, a delegation that differs from the zone, a DS that matches no key
- **Some failures are scheduled:** signatures and certificates expire on a date you can read today
- **So watch four things:** the servers (inside), the answers (outside), the zone across all its servers and its parent, and the clocks on signatures and certificates

---
<!-- _class: dense -->
## Black-Box and White-Box Monitoring

- **White-box:** "monitoring based on metrics exposed by the internals of the system": BIND's counters, logs, `rndc status`
- **Black-box:** "testing externally visible behavior as a user would see it": a probe asks a question and checks the answer
- **You need both:** in Lab 11.4 one fault leaves `named` running and its counters normal while nobody outside gets an answer; only the probe sees it
- **Where the probe stands decides what it sees:** inside your network it misses routing and anycast faults; outside it misses nothing it can reach, but you pay for the vantage points (section 3)
- **Probe the question users ask:** a name through a resolver, and the SOA from each listed server without recursion, not "is port 53 open"

<!--
Google SRE book, "Monitoring Distributed Systems" (Rob Ewaschuk), fetched 28 October 2026: "White-box monitoring: Monitoring based on metrics exposed by the internals of the system, including logs, interfaces like the Java Virtual Machine Profiling Interface, or an HTTP handler that emits internal statistics." "Black-box monitoring: Testing externally visible behavior as a user would see it." The book is a published practice text, not a standard; the definitions are used here because they are the common vocabulary.
-->

---
<!-- _class: dense table-compact -->
## Four Golden Signals, Applied to DNS

| Signal | Authoritative server | Resolver |
|---|---|---|
| **Latency** | probe RTT per server and per site; the slowest server matters (RFC 9199 C1, Module 5) | client answer time; time spent on upstream queries |
| **Traffic** | queries per second by type and transport | queries per second; recursions per second |
| **Errors** | REFUSED, SERVFAIL, NOTAUTH; transfer failures in the log | SERVFAIL ratio; validation failures; EDE codes seen |
| **Saturation** | rate-limit drops and slips, TCP clients, CPU | recursive clients against 900/1000, cache size against its limit |

- "If you can only measure four metrics of your user-facing system, focus on these four" (SRE book)
- Every row is a rate or a ratio over time: one reading of a counter says nothing (section 2)

<!--
SRE book: "The four golden signals of monitoring are latency, traffic, errors, and saturation. If you can only measure four metrics of your user-facing system, focus on these four." BIND 9.20.30: recursive-clients default 1000 with a soft quota of 90% (ARM; `rndc status` shows "recursive clients: 0/900/1000", Lab 11.1); tcp-clients 150 (`named -C`). Module 3 pointed here for "query and response rates, SERVFAIL rate, cache hit rate, recursive-clients in use".
-->

---
<!-- _class: dense table-compact -->
## SLIs, SLOs and the Registry Contract

- **SLI:** "a carefully defined quantitative measure of some aspect of the level of service"; **SLO:** "a target value or range of values for a service level that is measured by an SLI" (SRE book)
- Write DNS SLIs from the outside: "share of SOA probes from N places answered with `aa` within 500 ms", "share of resolver queries answered without SERVFAIL"
- gTLD registries have theirs in the contract (ICANN Base Registry Agreement, Specification 10; Module 9):

| Parameter | SLR (monthly) |
|---|---|
| DNS service availability | 0 min downtime = 100% availability |
| DNS name server availability | ≤ 432 min of downtime (≈ 99%) |
| UDP DNS resolution RTT | ≤ 500 ms, for at least 95% of the queries |
| DNS update time | ≤ 60 min, for at least 95% of the probes |

<!--
SRE book, "Service Level Objectives", fetched 28 October 2026. ICANN Base Registry Agreement approved 21 January 2024 (icann.org base-agreement page), Specification 10 §2.1, rows copied from the PDF; TCP RTT is "≤ 1500 ms, for at least 95% of the queries". §2.2: "any downtime, be it for maintenance or due to system failures, will be noted simply as downtime". "DNS service" means the whole service: every server down at once. ccTLDs set their own levels. Lab 11.2's DNSSlowAnswers alert uses the 500 ms figure.
-->

---
<!-- _class: dense -->
## Checks Across Servers and the Parent

- **Serials:** the SOA from every listed server, without recursion, with `aa`: one serial everywhere (Modules 2, 3, 5). A primary with dynamic signing raises it itself
- **NS sets:** the parent's delegation and the zone's own NS RRset should name the same servers (Module 1 Lab 1.3). RFC 7477 (CSYNC) lets a child ask the parent to follow; RFC 9975 (2026) clarifies CSYNC and CDS together
- **Glue:** the parent's addresses for in-zone servers equal the zone's A and AAAA records (RFC 9471)
- **DS against DNSKEY:** each DS at the parent matches a key the zone publishes, or validating resolvers fail (Lab 7.3's `wrongds.example`). CDS/CDNSKEY (RFC 7344, 8078) let the parent follow the child; with `parental-agents`, BIND checks the parent's DS itself (`rndc dnssec -status`, Module 7)
- **Lame servers:** a listed server that does not answer authoritatively. RFC 9499 quotes RFC 1912's definition and notes that the term now covers "a variety of other flaws in delegations"
- **The server list comes from the DNS:** a probe of fixed addresses never checks the server someone added yesterday (Lab 11.4)

<!--
RFC 1912 §2.8 (Informational, February 1996): "A lame delegations exists when a nameserver is delegated responsibility for providing nameservice for a zone (via NS records) but is not performing nameservice for that zone". RFC 9499 §2 (BCP 219) quotes it, adds RFC 1713's definition and says "there is no consensus on what a lame delegation is". RFC 7477 (Proposed Standard, March 2015, updated by RFC 9975, May 2026, "Clarifications on CDS/CDNSKEY and CSYNC Consistency"). RFC 7344 (CDS/CDNSKEY) and RFC 8078 (bootstrapping and deletion) are Module 7's; the lab zone has `parental-agents { "registry"; }` (Lab 7.2), so `rndc dnssec -status teamNN.example` and the dnssec log show whether BIND saw the DS at the parent. RFC 9471 (September 2023) for glue. labs/module11/tools/zonecheck.sh implements these checks with dig.
-->

---
<!-- _class: dense -->
## Clocks You Can Read Today

- **RRSIG expiration:** a zone whose signer stops goes bogus when its signatures expire. BIND's default policy signs for 14 days and refreshes 5 days before expiry; the lab policy signs for 30 minutes (Module 7)
- **RFC 6781 §4.4.2.2:** the minimum validity should cover the time "by which one would like to survive operational failure in provisioning", which "could easily suggest ... a few days"
- **Hand-signed zones:** `dnssec-signzone` signs for 30 days by default and nothing re-signs them: `manualNN.example` from Lab 7.1 expires 30 days after its start time, which `dnssec-signzone` sets one hour before you signed it (Lab 11.3 reads the date)
- **Certificates:** the DoT and DoH certificate from Module 8 is valid for 30 days; the probe in Lab 11.2 reads the days left
- **Alert on time left, with room to act,** below the refresh point so a healthy signer never alerts: with BIND's default policy warn under 4 days, page under 2; for the lab policy, minutes

<!--
BIND 9.20.30 `named -C`: dnssec-policy "default" { signatures-refresh P5D; signatures-validity P14D; signatures-validity-dnskey P14D; }. The lab policy: signatures-validity PT30M, signatures-refresh PT25M (the remaining validity stays above about 24 minutes while the signer runs). dnssec-signzone(1), BIND 9.20 ARM: end time default "30 days from the start time"; the start defaults to one hour before now. RFC 6781 (Informational, December 2012) §4.4.2.2 "Minimum Value", quoted. Module 7 pointed here: "your monitoring system for continuous ones".
-->

---
<!-- _class: dense table-compact -->
## The Course's Pointers, Collected

| From | What to monitor | Where today |
|---|---|---|
| Modules 1, 2, 3 | SOA serial on every server; the parent's NS, glue and DS against the zone | Labs 11.3-11.4 |
| Module 3 | query and response rates, SERVFAIL rate, cache hit rate, recursive clients | Labs 11.1-11.2 |
| Module 4 | statistics channel read by a monitoring system; dnstap; checks before NOTIFY at a registry | Labs 11.1-11.2; section 6 |
| Module 5 | each anycast instance (NSID on a normal query, not `id.server`); stale answers if serve-stale is on | section 3 |
| Module 6 | rate-limit drops, refused queries, security log categories | section 2 |
| Module 7 | signature expiry and the DS at the parent | Labs 11.3-11.4 |
| Module 8 | certificate expiry on DoT and DoH | Lab 11.2 |

<!--
Pointers found with grep "Module 11" in modules/: M1:893, M2:720, M3:326 and 656, M4:231, 310, 688, 833, M5:46, 293, 620, 716, M6:899, M7:877. Module 8 has no explicit pointer; its 30-day certificate (make-certs.sh) is the reason for the certificate probe. Module 4:833 (PowerDNS native replication and serials) is covered by the serial check: if serials do not move, the check cannot see a change.
-->

---
<!-- _class: section-divider -->
# 2 · Where the Numbers Come From

---
<!-- _class: dense -->
## BIND's Counters

```text
statistics-channels { inet 127.0.0.1 port 8053 allow { 127.0.0.1; }; };   // common/named.conf.stats
$ curl -s http://127.0.0.1:8053/json/v1/server | jq -r 'keys | join(" ")'
boot-time config-time current-time json-stats-version memory nsstats opcodes
qtypes rcodes sockstats traffic version views
$ sudo rndc stats        # the same counters, appended to /var/cache/bind/named.stats
```

- Module 4 opened the channel once; here it feeds a monitoring system. JSON under `/json/v1/`, XML under `/xml/v3/`
- **Keep it local:** with no `allow` clause, "named accepts connection attempts from any address", and the statistics "may contain sensitive internal information" (ARM)
- **Do not poll it too often:** "Gathering data exposed by the statistics channel locks various subsystems in named" (ARM). Every 15 seconds is plenty
- Counters are per server (`nsstats`, `rcodes`, `opcodes`), per view (`resolver.stats`, `cachestats`) and per zone (`zonestats`, if enabled)

<!--
BIND 9.20.30 ARM §8.2.17 "statistics-channels Block Definition and Usage", text from the bind9-doc package. Keys from Lab 11.1 (rehearsal 11.1.1b). Debian's build has --with-json-c and libxml2 (`named -V`).
-->

---
<!-- _class: dense -->
## Counters Become Rates

```text
$ sh tools/rates.sh 10          # on VM 2, while VM 1 runs dnsperf at 50 queries/s
over 10 s, per second:
  queries 49.9   NOERROR 43.7   NXDOMAIN 6.2   SERVFAIL 0   recursion 0.7
  cache hit ratio (client queries): 99%  (492 hits, 7 misses)
```

- A counter only grows, until `named` restarts and it starts again at zero: one reading means nothing; two readings and the time between them give a rate
- Prometheus does the same with `rate()`: "the per-second average rate of increase of the time series in the range vector", and it handles restarts ("counter resets")
- "Always take a `rate()` first, then aggregate": a sum of counters across restarts is wrong
- Ratios need a floor: 1 SERVFAIL out of 2 queries is 50% and means nothing (Lab 11.2's rule only counts when the resolver is busy)

<!--
Output from the rehearsal (11.1.2b; columns joined on the slide to fit; the script prints one per line). Prometheus documentation, query functions, fetched 28 October 2026: "rate(v range-vector) calculates the per-second average rate of increase of the time series in the range vector. Breaks in monotonicity (such as counter resets due to target restarts) are automatically adjusted for." and "always take a rate() first, then aggregate." Counter definition: "a cumulative metric that represents a single monotonically increasing counter whose value can only increase or be reset to zero on restart".
-->

---
<!-- _class: dense table-compact -->
## Counters Worth Watching

| Counter (`rndc stats` label / JSON name) | Tells you |
|---|---|
| queries resulted in SERVFAIL / `rcodes.SERVFAIL` | resolution or validation failing |
| queries caused recursion / `nsstats.QryRecursion` | cache misses that cost an upstream query |
| cache hits (from query), cache misses (from query) / `cachestats.QueryHits`, `QueryMisses` | the hit ratio clients feel |
| `nsstats.QryDropped` | recursive queries dropped by `fetches-per-*`, `clients-per-query`, rate limits |
| `nsstats.RateDropped`, `RateSlipped` | responses dropped or truncated by RRL (Module 6) |
| `rndc status`: recursive clients 0/900/1000, recursive high-water | load now, soft and hard limit, peak since start |
| auth/recursive queries rejected | probing or open-resolver scans (Module 6) |

<!--
ARM §"The Statistics Counters" (9.20.30): QryRecursion "the number of queries that caused the server to perform recursion in order to find the final answer"; QryDropped "the number of recursive queries dropped by the server as a result of configured limits. These limits include the settings of the fetches-per-zone, fetches-per-server, clients-per-query, and max-clients-per-query options, as well as the rate-limit option"; RateDropped "responses dropped due to rate limits", RateSlipped "responses truncated by rate limits". The cache labels are from `rndc stats` output on VM 2 ("cache hits (from query)"); the ARM's counter list does not describe the JSON cachestats names, which were matched to these labels by comparing the two outputs.
-->

---
<!-- _class: dense -->
## Logs: What They Hold and What They Cost

- **Categories** (Module 6): `security`, `rate-limit`, `xfer-in`, `xfer-out`, `notify`, `dnssec`, `lame-servers` tell you what happened to the zone and the server, at low volume
- **The query log** (`rndc querylog on`) writes one line per query: fine for minutes of troubleshooting, costly at full rate
- **Refusals:** an ACL denial for a zone the server serves is logged at `info` in `security` (`query '...' denied`); a query refused because recursion is not allowed for the client (EDE 20) is not logged, on either VM: count those (`recursive queries rejected`)
- **Log lines worth an alert:** "transferred serial" missing for hours, "refresh: failure", "no valid signature found", "broken trust chain", "received notify for zone ... NOTAUTH"
- **Client addresses are personal data:** RFC 8932 (BCP 232): "data retention should be minimized or completely avoided if possible" and logs kept "only as long as is required to sustain operation of the service" (Module 8)
- Ship logs off the server (journald forwarding, syslog): a server that fails takes its local logs with it

<!--
RFC 8932 (BCP 232, October 2020) §5.2.1 "Data Handling", wording quoted from the text. The log lines are from the Module 11 rehearsal: "received notify for zone 'team01.example': NOTAUTH" on VM 2 during fault 2; "validating team01.example/DNSKEY: no valid signature found (DS)" and "broken trust chain resolving 'www.team01.example/A/IN'" during fault 3. Refusals, tested 28 October 2026 on the stand-in VMs (plan/m11_notes.md): a query from the registry's address to VM 2 for _dns.resolver.arpa (a zone VM 2 serves, allow-query trusted) gave REFUSED with EDE 18 and the line "client ... 192.0.2.53#41726 (_dns.resolver.arpa): query '_dns.resolver.arpa/SVCB/IN' denied" (BIND logs it in category security at info, lib/ns/query.c); recursive queries from that address to VM 2, and from VM 2 to VM 1 (recursion no), gave REFUSED with EDE 20 "recursion disabled" and no log line, only "recursive queries rejected" in rndc stats. Module 6's table said refused queries are not logged at info: true for the second case only (corrected there too).
-->

---
<!-- _class: dense -->
## dnstap

```text
dnstap { client; resolver query; };                          // vm2/dnstap.options
dnstap-output file "/var/cache/bind/dnstap.fstrm" size 20m versions 3;
$ sudo rndc dnstap -roll; sudo dnstap-read /var/cache/bind/dnstap.fstrm.0
27-Oct-2026 21:30:35.215 CQ 127.0.0.1:51865 -> 127.0.0.1:53 UDP 59b www.team01.example/IN/A
27-Oct-2026 21:30:35.215 RQ 0.0.0.0:47479 -> 192.0.2.30:53 UDP 59b www.team01.example/IN/A
27-Oct-2026 21:30:35.215 CR 127.0.0.1:51865 <- 127.0.0.1:53 UDP 91b www.team01.example/IN/A
```

- "A flexible, structured binary log format for DNS software": whole messages in Protocol Buffers over Frame Streams (fstrm), written by the server itself, no packet capture
- BIND logs `client`, `auth`, `resolver`, `forwarder`, `update` messages, each query, response or both; Debian builds it in (`--enable-dnstap`)
- `dnstap-read -y` prints every message in full; `fstrm_capture` (Debian `fstrm-bin`) receives a stream over a socket for a collector
- Same privacy rules as the query log; bound the file (`size`, `versions`) and remove it after use; it is in `/var/cache/bind` because Debian's AppArmor profile lets `named` write there

<!--
Output from Lab 11.1's exploration (plan/m11_notes.md; the harness checks the same CQ and RQ lines, 11.1.5b). dnstap.info, fetched 28 October 2026: "dnstap is a flexible, structured binary log format for DNS software. It uses Protocol Buffers to encode events". ARM 9.20.30 `dnstap` and `dnstap-output` grammar; rndc(8): "rndc dnstap -roll causes the output file" to be rolled. CQ/CR: client query/response; RQ: resolver query (the resolver's source address shows as 0.0.0.0 unless query-source is set, as the ARM notes).
-->

---
<!-- _class: dense table-compact -->
## Other Tools and Other Servers

| Tool | Debian 13 | What it gives |
|---|---|---|
| `tshark`, `tcpdump` | packaged (Modules 1, 6) | any server's traffic, at the cost of capturing packets |
| `dnscap` 2.3.1, `dnstop` | packaged | DNS-aware capture with rotation; live top-N tables |
| DSC (DNS Statistics Collector) | **not packaged** | dashboards from captures, used by many TLDs |
| `unbound-control stats_noreset` | packaged with Unbound (Module 4) | Unbound's counters without zeroing them |
| collectd 5.12, zabbix-agent 7.0 | packaged | general monitoring agents with BIND plug-ins or templates |
| Monitoring Plugins (`check_dig`, `check_dns`; contrib `check_soas`, `check_zone_rrsig_expiration`) | packaged | Nagios-style checks; the contrib DNS checks start at the real root servers, so they cannot check the lab TLD offline |

<!--
Debian 13 apt-cache policy, 28 October 2026: dnscap 2.3.1-1, dnstop 20240820-1, collectd 5.12.0-26, zabbix-agent 1:7.0.22+dfsg-1~deb13u1, monitoring-plugins-standard 2.4.0-3+deb13u1, monitoring-plugins-contrib 48.20250420; dsc-statistics-collector and nagios-plugins-contrib not found. Tested: check_zone_auth and check_zone_rrsig_expiration (Perl, Net::DNS) printed "unresolvable name: a.root-servers.net ..." and "No response to seed query" in the isolated lab; they walk from the root. Use `unbound-control stats_noreset`, not `stats`, if anything else reads the same counters: `stats` resets them.
-->

---
<!-- _class: section-divider -->
# 3 · Collecting, Alerting, Looking from Outside

---
<!-- _class: dense -->
## Prometheus in One Slide

- **Pull:** every 15 s Prometheus scrapes `/metrics` from each target (an exporter) and stores numbered samples in its own time-series database (15 days by default)
- **Exporters translate:** bind_exporter reads the statistics channel; the blackbox exporter runs a probe when asked and reports the result as metrics
- **PromQL:** `rate(bind_incoming_queries_total[1m])`, `probe_success == 0`, `probe_dns_serial`; `promtool query instant` asks from the shell
- **Rules:** an alert is a PromQL expression that holds `for` a time; Alertmanager (packaged) groups and routes the notifications
- **Debian 13:** `prometheus` 2.53.3, `prometheus-bind-exporter` 0.8.0, `prometheus-blackbox-exporter` 0.26.0, `prometheus-alertmanager` 0.28.1; Grafana is not packaged, Prometheus has its own graph page
- Other stacks do the same job (Zabbix, collectd, a provider's service): the checks matter more than the tool

<!--
Debian 13 packages checked 28 October 2026. bind_exporter v0.8.0 (2024-11-06) source: listen ":9119", --bind.stats-url default "http://localhost:8053/", --bind.stats-groups default "server,view". blackbox_exporter v0.26.0 (2025-02-26). Retention: `prometheus --help` "the retention time defaults to 15d". In the lab Prometheus used 78 MiB resident, the blackbox exporter 25 MiB and bind_exporter 22 MiB (test host, one sample).
-->

---
<!-- _class: dense -->
## The Lab's Monitoring Stack

```text
 VM 1 192.0.2.30                         VM 2 192.0.2.10
 named ── :8053 (127.0.0.1) ─┐            named ── :8053 (127.0.0.1) ── bind_exporter :9119 (127.0.0.1)
                             │                                                    │ scrape
 bind_exporter 192.0.2.30:9119 ───────── scrape ──────────── Prometheus :9090 (127.0.0.1) ── rules
                                                                       │ ?target=…&module=…
 named :53  ◄─── SOA, no recursion ───────── blackbox :9115 (127.0.0.1) ──► VM 2 :53 www A
                                                              └──────────► VM 2 :853 TLS
```

- Six targets: Prometheus itself, two bind_exporters, three probes (SOA at VM 1, a name through VM 2, the DoT handshake)
- Every listener on 127.0.0.1 except VM 1's exporter, which VM 2 must reach; Debian's default is every address. See the page with `ssh -L 9090:127.0.0.1:9090 <VM 2>`
- In production Prometheus sits on its own host, and the probes run from several networks

<!--
The kit's /etc/default files set the listen addresses (labs/module11/vm1, vm2). Debian's prometheus default --web.listen-address is "0.0.0.0:9090" (`prometheus --help` in the package); the exporters' defaults are ":9115" and ":9119". bind_exporter has no access list; the kit's comment points to --web.config.file (TLS and basic authentication, exporter-toolkit) or a firewall rule.
-->

---
<!-- _class: dense -->
## Probes That Check the Answer

```yaml
soa_teamNN:                       # vm2/blackbox.yml
  prober: dns
  dns:
    preferred_ip_protocol: ip4    # default ip6
    query_name: teamNN.example
    query_type: SOA               # default ANY
    recursion_desired: false      # default true
    valid_rcodes: [NOERROR]
    validate_answer_rrs:
      fail_if_none_matches_regexp: ['^teamNN\.example\.\s.*\sSOA\s']
```

- A probe that accepts any answer only proves the port is open; this one fails on REFUSED, SERVFAIL, an empty answer or a referral
- SOA probes also export `probe_dns_serial`: with every listed server as a target, one rule compares the serials
- The `dot_tls` module (TCP with TLS, the team CA, the resolver's name) exports `probe_ssl_earliest_cert_expiry`

<!--
blackbox_exporter v0.26.0 CONFIGURATION.md, dns_probe section (saved verbatim in the scratch sources): defaults query_type "ANY", recursion_desired true, valid_rcodes NOERROR, preferred_ip_protocol "ip6". prober/dns.go at v0.26.0: probe_dns_serial "Returns the serial number of the zone", registered only for SOA queries. In the rehearsal (11.2.4) probe_dns_serial for VM 1 equalled bind_zone_serial for team01.example from VM 1's exporter: the black-box and white-box views agree.
-->

---
<!-- _class: dense -->
## Alert Rules

```yaml
- alert: DNSProbeFailed                       # vm2/dns-rules.yml (six rules)
  expr: probe_success{job=~"dns_soa|dns_resolve|dot"} == 0 or up{job=~"dns_soa|dns_resolve|dot"} == 0
  for: 1m
  labels: {severity: page}
  annotations:
    first_check: "dig the same question at {{ $labels.instance }}; then the server's log"
- alert: DNSSerialsDiffer
  expr: count(count_values("serial", probe_dns_serial{job="dns_soa"})) > 1
  for: 5m
```

- `for`: Prometheus waits "between first encountering a new expression output vector element and counting an alert as firing"; until then the alert is **pending**
- The other rules: slow answers (over 500 ms for 5 minutes), resolver SERVFAIL ratio over 5% while busy, BIND counters missing, the DoT certificate under 14 days
- Rehearsed (six runs): `named` stopped on VM 1, DNSProbeFailed fired 65-86 s later (15 s scrapes plus `for: 1m`) and cleared 14-29 s after `named` came back

<!--
Prometheus alerting-rules documentation, fetched 28 October 2026: "The optional for clause causes Prometheus to wait for a certain duration between first encountering a new expression output vector element and counting an alert as firing for this element." "Elements that are active, but not firing yet, are in the pending state." Timings from six rehearsal runs (11.2.5, 11.2.5b) on the test host. The SERVFAIL ratio rule first had no floor: in the rehearsal it kept firing for minutes after a fault, on a resolver that saw only the probe's query every 15 s.
-->

---
<!-- _class: dense -->
## Alerts People Act On

- "Every page should be actionable", and a pager can only be answered "with a sense of urgency a few times a day before I become fatigued" (SRE book)
- **Page on symptoms users feel** (failed answers, SERVFAIL ratio, signatures with hours left); **ticket the rest** (serials apart for 5 minutes, certificate under 14 days)
- **Each alert carries its first check:** the annotation says which command to run, so the person woken up starts with evidence
- **Alertmanager:** "Grouping categorizes alerts of similar nature into a single notification"; "Inhibition is a concept of suppressing notifications for certain alerts if certain other alerts are already firing"; "Silences are a straightforward way to simply mute alerts for a given time"
- **Test every alert:** break the thing on purpose and time the alert (Lab 11.2). An alert that has never fired may never fire
- **Notifications must not depend on the DNS you monitor:** a mail server or chat service that needs your zone is down when you need it

<!--
SRE book, "Monitoring Distributed Systems": "Every time the pager goes off, I should be able to react with a sense of urgency. I can only react with a sense of urgency a few times a day before I become fatigued." and "Every page should be actionable." Alertmanager documentation, fetched 28 October 2026, sentences quoted. The lab runs no Alertmanager: alerts are read with tools/alerts.sh (Prometheus's /api/v1/alerts).
-->

---
<!-- _class: dense -->
## Checks a Probe Cannot Make

```text
$ sh tools/zonecheck.sh teamNN.example 192.0.2.53 192.0.2.10 1200 600
ZONECHECK OK: team01.example, 1 server(s) at the parent, 1 in the zone
OK: ns1.team01.example. (192.0.2.30): serial 2026102745, SOA signature expires in 28 minutes
OK: DS 33121 matches a DNSKEY in the zone
OK: DNSKEY signature expires in 27 minutes
```

- Takes the server list from the parent's referral **and** the zone's NS RRset, then asks each one for the SOA without recursion: `aa`, serial, signature time
- Compares the two NS sets, the glue with the zone's addresses, each DS with the zone's DNSKEYs (`dnssec-dsfromkey`)
- Exit codes from the Monitoring Plugins guidelines: 0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN, so any scheduler (cron, a systemd timer, Nagios, Zabbix) can act on it. The first line is the verdict (the guidelines ask for one line); the details follow for people
- Online alternatives for real zones: Zonemaster (AFNIC and the Swedish Internet Foundation) and DNSViz (packaged in Debian 13)

<!--
Output from the rehearsal (11.3.1 family; serial and key tag differ per run). Monitoring Plugins Development Guidelines §2.4, Table 2 "Plugin Return Codes" (monitoring-plugins.org, fetched 28 October 2026): 0 OK, 1 Warning, 2 Critical, 3 Unknown; §2.1 "Print only one line of text". Zonemaster site footer "Copyright © AFNIC and The Swedish Internet Foundation", latest release v2026.1.2 (1 October 2026); DNSViz "a tool for visualizing the status of a DNS zone", Debian 13 dnsviz 0.11.1-1, upstream 0.11.2 (3 October 2026). Neither can reach the lab's private example. TLD.
-->

---
<!-- _class: dense -->
## Looking from Outside Your Network

- **Your probes see your catchment:** an anycast fault in another region, a routing leak or a filtering ISP is invisible from your own network (Module 5)
- **RIPE Atlas:** "DNS" is one of its measurement types; "for DNS measurements, the target refers to the resolver that will be used"; "You need to have sufficient credits to create a measurement" (UDP 10 credits per result). Probe hosts earn credits
- **Ask with NSID on a normal query** to learn which instance answered: BIND rate-limits `id.server` and `hostname.bind` to 3 answers per second (Module 5), so a fleet of probes asking them sees silent drops
- **Commercial services** (for example ThousandEyes, "a network intelligence SaaS platform"): many vantage points, at a price and with your data on their side; no lab uses one
- **Users are a vantage point too:** a status page and a reporting address outside your own zone

<!--
RIPE Atlas documentation, fetched 28 October 2026 (credits page dated 2026-09-23): "You need to have sufficient credits to create a measurement."; measurement types "Ping", "Traceroute", "DNS", "SSL" (TLS) and "NTP"; "DNS and DNS6 ... Unit cost for UDP: 10 credits/result"; API: DNS measurements can set "NSID". ThousandEyes documentation ("Welcome to ThousandEyes, a network intelligence SaaS platform"); the product page refused automated fetches. Module 5's finding: `named -C` shows the _bind view's rate-limit { responses-per-second 3; slip 0; }.
-->

---
<!-- _class: section-divider -->
# 4 · Performance and Capacity

---
<!-- _class: dense -->
## What Sets a Resolver's Speed

- **The cache hit ratio:** a hit costs microseconds of CPU; a miss costs one or more round trips to authoritative servers and their validation
- **The authoritative servers' distance and health:** a lame or slow listed server costs every resolver that picks it (Lab 11.4 fault 2)
- **Validation:** DNSKEY and DS fetches on misses; cached afterwards
- **Negative answers:** `synth-from-dnssec` (RFC 8198, default `yes`) answers non-existent names from cached NSEC records. The ARM: "This initial implementation only covers synthesis of answers from NSEC records". The lab zones use NSEC3, so every new name costs a query
- **Transport:** TCP and TLS cost connection set-up; truncated UDP answers force a TCP retry (Module 6)

<!--
BIND 9.20.30 ARM, synth-from-dnssec: "Enables support for RFC 8198, Aggressive Use of DNSSEC-Validated Cache." "The default is yes." "This initial implementation only covers synthesis of answers from NSEC records; synthesis from NSEC3 is planned for the future." RFC 8198 (Proposed Standard, July 2017, updated by RFC 9077). The lab policy has nsec3param iterations 0 (Module 7, RFC 9276), and Lab 7.1 signs with -3 -.
-->

---
<!-- _class: dense table-compact -->
## Measured in Lab 11.1

| `dnsperf -s VM2 -Q 50 -l 10` from VM 1 | Names that exist (8, repeated) | 500 unique non-existent names |
|---|---|---|
| Answered | 500 of 500 | 500 of 500, all NXDOMAIN |
| Average latency | 0.141-0.180 ms | 1.109-1.225 ms (6 to 9 times longer) |
| Cache hit ratio (client queries) | 99% (491-492 hits, 7 misses) | 0% (0 hits, 498-499 misses) |
| Recursions per second | 0.7 | 49.8-49.9 (one per query) |
| VM 1 (authoritative) | almost idle | 500 more NXDOMAIN answers, no RRL drops (cookies) |

- A lab, not your hardware: two containers on one Docker bridge on a 12-CPU host. Compare the two columns with each other, never with a datasheet
- The second column is a random-subdomain flood at a polite rate (Module 6): the cache cannot help, the authoritative server pays
- Recommendation from these numbers: watch the hit ratio and recursions per second, not only queries per second

<!--
Measured 28 October 2026 in six rehearsal runs (rehearse.sh 11.1.2-11.1.3b, the ranges are across the runs; the harness checks hit ratio ≥95% and 0%, recursion 40-59 per second, and that the unique run is more than twice as slow). The exploration run gave 0.157 ms and 1.239 ms. VM 1's nsstats after the unique run (exploration): QryNXDOMAIN 501, CookieMatch 509, no RateDropped: the resolver's queries carry server cookies, which RRL does not limit (Module 6).
-->

---
<!-- _class: dense -->
## dnsperf and resperf

- **dnsperf:** "primarily intended for measuring the performance of authoritative DNS servers, but it can also be used for measuring caching server performance in a closed laboratory environment"; `-Q` caps the rate, `-l` the duration
- **resperf:** "sending DNS queries at a controlled, steadily increasing rate" until "the query rate will at some point exceed the capacity of the server and queries will be dropped". It finds a breaking point: theory only in this course
- **Only against your own servers**, and only at rates you have agreed with whoever runs the network (Module 6's rule: `-Q 50 -l 10`)
- **Use real query mixes:** replay names from your dnstap or query log, with the right share of misses and non-existent names; eight names repeated measure the cache only
- **Change one thing, measure again;** keep the command, the query file and the versions with the numbers (Module 4: measure, do not copy benchmarks)

<!--
dnsperf.1 and resperf.1 (DNS-OARC, repository moved to Codeberg; text from the GitHub copy of the man page sources, fetched 28 October 2026). Debian 13 dnsperf 2.14.0-5 contains both. Module 4's slide on choosing software already says "measuring instead of copying benchmarks".
-->

---
<!-- _class: dense table-compact -->
## BIND's Limits and Knobs

| Option (9.20 default) | What it limits | Watch |
|---|---|---|
| `recursive-clients` 1000 (soft quota 900) | recursions in progress; each uses "on the order of 20 kilobytes" | `rndc status`: recursive clients, high-water |
| `clients-per-query` 10, `max-clients-per-query` 100 | clients waiting for one identical question | QryDropped |
| `fetches-per-zone` 0 (Module 6 set 100 `fail`), `fetches-per-server` 0 | upstream queries to one zone or one server | QryDropped, the log |
| `max-cache-size` 90% of memory (2 MB with `recursion no`) | the cache; then "named starts purging non-expired records" | cache memory in `rndc stats` |
| `tcp-clients` 150 | TCP connections | TCP high-water |
| `servfail-ttl` 1 | how long a SERVFAIL is cached | SERVFAIL ratio |

- Raise a limit when its high-water mark and drop counters say so, not before; most limits protect the server from attacks (Module 6)

<!--
BIND 9.20.30 `named -C` (recursive-clients 1000, clients-per-query 10, max-clients-per-query 100, fetches-per-server 0, fetches-per-zone 0, max-cache-size default, tcp-clients 150, servfail-ttl 1) and ARM text for recursive-clients (soft quota "set to 90% of recursive-clients" when 1000 or less; "on the order of 20 kilobytes") and max-cache-size ("90% of physical memory for views with recursion set to yes (the default), or 2 MB for views with recursion set to no"). Module 6's resolver options set fetches-per-zone 100 fail.
-->

---
<!-- _class: dense -->
## Capacity Planning

- **Measure your peak, not your average:** the busiest minute of the busiest day, from your rates, and its growth over months
- **N+1 per role and per site:** lose one server or one anycast site and the rest still carries the peak (Module 5's catchments move with it)
- **Headroom for attacks:** a random-subdomain flood is all misses (previous slide); RFC 9199 C4 describes two choices under stress, withdrawing routes or staying as a "degraded absorber"
- **Know the first limit you will hit:** recursive clients, upstream fetches, CPU, the link, the authoritative server's rate limit; the high-water marks tell you which one is closest
- **Memory:** the cache fills to its limit by design; size it from the hit ratio you need, not the memory you have
- **Re-test after every major upgrade:** the same query file, the same commands, the old numbers next to the new

<!--
RFC 9199 §3.4.2 (C4): operators can withdraw routes ("withdrawing routes, prepending ...") or "become degraded absorbers by continuing to operate, knowing dropping incoming legitimate requests due to queue overflow" (§3.4.1). Module 5 covers anycast withdrawal and catchments.
-->

---
<!-- _class: dense -->
## Authoritative Servers Under Load

- **Rate limiting changes the numbers:** VM 1 limits identical responses to 5 per second per client network (Module 6), but queries with a valid server cookie pass; Lab 11.1's 500 NXDOMAIN answers to VM 2 had 509 cookie matches and no drops
- **Watch drops and slips:** `RateDropped` and `RateSlipped` rising with normal traffic means the limit is too tight for a large resolver behind NAT
- **Big answers:** DNSKEY sets, ANY and TXT answers decide the bytes per second; responses over 1232 octets go to TCP (Module 6)
- **Zone size and reload time:** a zone of millions of names reloads in seconds to minutes; time it, and watch "loaded serial" in the log after each change
- **Transfers:** time from NOTIFY to "transferred serial" on every secondary is the propagation SLI (Spec 10's "DNS update time")

<!--
Module 6 Lab 6.3 set rate-limit { responses-per-second 5; window 5; slip 2; log-only no; } on the authoritative VM; Module 6's ruling records that cookies exempt the resolver's queries after one BADCOOKIE retry. Lab 11.1 counters: VM 1 nsstats QryNXDOMAIN 501, CookieMatch 509, RateDropped absent (zero). ICANN Spec 10 "DNS update time ≤ 60 min, for at least 95% of the probes".
-->

---
<!-- _class: section-divider -->
# 5 · Incident Response

---
<!-- _class: dense -->
## An Incident's Life

- **NIST SP 800-61 Rev. 3** (April 2025) uses "the CSF 2.0 Functions, Categories, and Subcategories to organize its recommendations": Govern, Identify, Protect before; "Incident response is shown in the top level of the figure: Detect, Respond, and Recover"
- **Detect:** an alert, a check, a user report; write down when and how
- **Respond:** contain the damage, find the cause from evidence, fix, and tell people what is happening
- **Recover:** verify with the same checks that found it, watch for the next TTL to pass, then close
- **Govern and Identify are the preparation:** who is on call, the contacts, the runbooks, the inventory of zones, servers, keys and registrar accounts
- SP 800-61 is written for security incidents; a DNS outage that is not an attack uses the same cycle

<!--
csrc.nist.gov, SP 800-61 Rev. 3, "Date Published: April 2025", "Supersedes: SP 800-61 Rev. 2 (08/06/2012)"; Rev. 2 page: "Withdrawn on April 03, 2025". Quotes from the PDF: "This publication uses the CSF 2.0 Functions, Categories, and Subcategories to organize its recommendations, considerations, and other information regarding incident response as a CSF 2.0 Community Profile." and "Incident response is shown in the top level of the figure: Detect, Respond, and Recover."
-->

---
<!-- _class: dense -->
## Roles and Communication

- **One incident lead** decides; one person talks to users and management; one writes the timeline. In a small team the roles are hats, not people
- **Know who else can act:** your registrar and the registry (DS, NS, registry lock: Module 9), your DNS providers and secondaries, your upstream networks, the CA for your certificates
- **Keep their contacts and your account credentials where the incident cannot reach them:** a status page and an e-mail address that do not depend on your own zone
- **Say what users should do,** what you know, what you do not, and when you will update; timestamps in UTC
- **Change control still applies:** one change at a time, written down with its time and its undo

---
<!-- _class: dense -->
## First Questions for a DNS Incident

1. **Who is affected?** One resolver, one region, only validating resolvers, only TCP, everyone? Ask through several resolvers, and with `+cd`
2. **Do the servers answer?** Each listed server directly, `+norec`: status, `aa`, serial (`zonecheck.sh`, Module 5's SOA loop)
3. **Does the parent agree?** NS, glue, DS at the registry against the zone (`dig @registry zone NS +norec`, `DS`)
4. **Does validation pass?** `delv`, the resolver's log, EDE codes when the resolver gives one (Module 7)
5. **What changed?** Zone serials, configuration, certificates, keys, network, the registry account: the last change is the first suspect
6. **What does the monitoring show, and since when?** The first alert's time is the start of your timeline

<!--
Order matters: questions 1-3 need no access to the servers and can run while someone logs in. In Lab 11.4 fault 3 the resolver gave SERVFAIL with no EDE code (BIND 9.20.30, rehearsal 11.4.3), although RFC 8914 defines EDE 9 "DNSKEY Missing" for "A DS record existed at a parent, but no supported matching DNSKEY record could be found for the child"; do not wait for an EDE code to appear.
-->

---
<!-- _class: dense -->
## Fast Fixes and Their Traps

- **Roll back the zone:** keep the last good version; the serial must still go up, or secondaries ignore the fix (Module 5)
- **A wrong DS:** fix it at the registry; resolvers that cached the bad DS keep failing until its TTL runs out (Lab 11.4 rehearsal: SERVFAIL began 103-115 s after the bad DS, AD returned 57-60 s after the fix, with TTL 60)
- **Do not pull signing while a DS is cached:** remove the DS first, wait out its TTL, then stop signing (the Slack case)
- **Negative trust anchors** (RFC 7646) are a resolver operator's tool for someone else's broken zone, not a fix for your own; they must be removed again
- **Hijack or account compromise:** registrar and registry first, then the servers (Module 6, CISA ED 19-01; Module 9, registry lock)
- **Serve-stale** (Module 5) hides an outage from users for up to `max-stale-ttl`, and from your monitoring too: count stale answers

<!--
Lab 11.4 timings from six rehearsal runs (11.4.3, 11.4.3d), lab TTLs (60 s for the DS and the zone). RFC 7646 (Informational, September 2015) §4 on removal; "the NTA may be in place after the time when the DNS misconfiguration that caused validation to break has been fixed". BIND 9.20.30 max-stale-ttl 86400 (one day) when serve-stale is enabled.
-->

---
<!-- _class: dense -->
## Case: Meta, 4 October 2021

- During routine maintenance "a command was issued with the intention to assess the availability of global backbone capacity, which unintentionally took down all the connections in our backbone network"; "a bug in that audit tool prevented it from properly stopping the command"
- "Our DNS servers disable those BGP advertisements if they themselves can not speak to our data centers, since this is an indication of an unhealthy network connection"
- With the backbone gone, every site declared itself unhealthy: "The end result was that our DNS servers became unreachable even though they were still operational"
- **The lessons for DNS operators:** a health check that withdraws routes (Module 5) can withdraw every site at once; keep at least one path that does not depend on the same signal, and keep out-of-band access to the tools that fix it
- **Monitoring view:** every server was healthy from the inside; only probes from outside could see the service had gone

<!--
Meta engineering blog, "More details about the October 4 outage", Santosh Janardhan, posted 5 October 2021 (engineering.fb.com, fetched 28 October 2026); sentences quoted verbatim. The earlier post of 4 October 2021: "configuration changes on the backbone routers that coordinate network traffic between our data centers caused issues that interrupted this communication".
-->

---
<!-- _class: dense -->
## Case: Slack, 30 September 2021

- "On September 30th 2021, Slack had an outage that impacted less than 1% of our online user base, and lasted for 24 hours"
- After "a three hour 'soak time' and successful validations" the DS was published at the registrar; some resolvers then failed to find records because of "an issue with NSEC responses that Route 53 generated on wildcard records"
- The team pulled the DS and then rolled signing back; "all DNSSEC validating resolvers that had recently cached the DS record for slack.com started returning a SERVFAIL on all slack.com lookups"
- "The '.com.' zone will ask resolvers to cache the slack.com DS record for 24h by default"; error rates went back to normal "as the 24h TTL on the DS record at the '.com' zone expired"
- **The lessons:** a DS change lasts as long as the parent's TTL; remove the DS and wait it out before you stop signing; test signed zones through validating resolvers, including wildcards and non-existent names

<!--
Slack engineering blog, "What happened during Slack's DNSSEC rollout?", dated 29 November 2021 (slack.engineering, fetched 28 October 2026); sentences quoted verbatim. The order of steps is from the post: DS published, NODATA reports, DS pulled, signing rolled back. Lab 11.4 fault 3 is the same failure on a 60-second TTL.
-->

---
<!-- _class: dense -->
## After the Incident

- **Write the record the same day** (`labs/module11/incident-record.md`): timeline in UTC, how it was detected, impact, evidence with the commands, cause, fix, verification
- **Two numbers:** time to detect (start to first alert or report) and time to recover (detection to verified); the start is often earlier than the first alert, so look in the counters
- **Ask why the monitoring did not catch it sooner,** and add the check that would have (Lab 11.4 fault 2: a server list taken from the DNS, not from a config file)
- **Blame the system, not the person:** the useful question is what made the mistake easy and the detection slow
- **Turn each lesson into a change with an owner and a date:** a check, an alert, a runbook line, a TTL, a test
- **Share the record:** the next person on call starts from it

---
<!-- _class: section-divider -->
# 6 · Continuity and Recovery

---
<!-- _class: dense -->
## RTO, RPO and MTD for DNS

- **RTO:** "the maximum amount of time that a system resource can remain unavailable before there is an unacceptable impact on other system resources, supported mission/business processes, and the MTD"
- **RPO:** "the point in time, prior to a disruption or system outage, to which mission/business process data can be recovered (given the most recent backup copy of the data)"
- **MTD:** "the total amount of time the system owner/authorizing official is willing to accept for a mission/business process outage or disruption" (all three: NIST SP 800-34 Rev. 1)
- **For DNS, RTO is per layer:** answering (secondaries and caches keep it short), changing the zone (the hidden primary), signing (bounded by signature validity), changing the delegation (the registry)
- **RPO is about the zone data and the keys:** losing the last hour of changes is an RPO question; losing a KSK private key is a rollover

<!--
NIST SP 800-34 Rev. 1, "Contingency Planning Guide for Federal Information Systems", May 2010, updated 11 November 2010 (csrc.nist.gov, still the current revision on 28 October 2026; no Rev. 2 found), §3.2, definitions quoted verbatim.
-->

---
<!-- _class: dense table-compact -->
## What Keeps Answering When Something Fails

| Lost | What carries on | For how long |
|---|---|---|
| The hidden primary | secondaries serve their copy | until the SOA EXPIRE ("the upper limit on the time interval that can elapse before the zone is no longer authoritative"): 2 weeks in the lab zone |
| The signer | the signed zone, unchanged | until the first signatures expire: 5 to 14 days with BIND's default policy (signatures are refreshed when 5 days remain), 25-30 minutes with the lab policy |
| Every listed server | resolvers' caches | each record's TTL; with serve-stale, up to `max-stale-ttl` (1 day in BIND) |
| The registry or registrar | the delegation already published | indefinitely, but no NS or DS change is possible |
| A KSK private key | nothing to sign new DNSKEY sets | until the DNSKEY signatures expire, then bogus |

- "Time to bogus" is a number to monitor: the earliest signature expiry on every server (Lab 11.3)

<!--
RFC 1035 §3.3.13 EXPIRE definition quoted. Module 2's zone template: expire 1209600 (2 weeks). BIND 9.20.30 `named -C`: dnssec-policy "default" signatures-validity P14D, signatures-refresh P5D; max-stale-ttl 86400. Resolvers may cap TTLs (max-cache-ttl, Module 5).
-->

---
<!-- _class: dense -->
## What to Back Up and Test

- **Zone sources:** the files or database the hidden primary loads, with their history (Git, the registry database); not only the signed output
- **DNSSEC keys and state:** the key files and BIND's key state (`.state` files in the key directory), or the HSM backup; without them a restore is an emergency rollover (Module 7)
- **Configuration and secrets:** `named.conf` files, TSIG keys (Module 6), certificates and their keys (Module 8), the monitoring configuration itself
- **Accounts:** registrar and registry access, second factors, the DS records you published; held by more than one person
- **Test the restore:** build a server from the backup on a spare VM, compare its answers with the live ones (Module 4's `zonediff.sh` idea), time it: that time is your real RTO
- **Registries add checks before NOTIFY** (Module 4): a zone that fails its checks is not published, so a broken build never reaches the secondaries

<!--
BIND 9.20 keeps dnssec-policy key state in K*.state files next to the .key and .private files in the key-directory (Module 7). Module 4 pointed here for "the registry needs checks before NOTIFY".
-->

---
<!-- _class: dense table-compact -->
## Disaster Scenarios to Rehearse

| Scenario | First actions | Limit to beat |
|---|---|---|
| Hidden primary lost | secondaries keep serving; restore or promote one; re-point NOTIFY and transfers | SOA EXPIRE |
| Signer lost, keys safe | restore keys and state on a new signer; check signatures before NOTIFY | first signature expiry |
| KSK compromised | emergency KSK rollover with the registry (Module 7) | the DS TTL and the registry's process |
| Registrar account taken over | registry lock and the registrar's emergency contact (Module 9); CISA ED 19-01 steps (Module 6) | the NS and DS TTLs at the parent |
| One provider out | the other providers' servers answer; remove the dead one only if it answers wrongly | resolvers retry on their own |
| Certificate expired (DoT, DoH) | clients in strict mode fail, opportunistic ones fall back: renew, then fix the alert | the probe's 14-day warning |

---
<!-- _class: dense -->
## Exercise: A Tabletop

At 02:10 UTC the on-call engineer gets "DNSProbeFailed" for ns2 only. At 02:25 the support desk reports that customers of one ISP cannot reach the web site; others can. At 02:40 someone notices that a zone change was pushed at 01:55 with the same serial.

1. What do you check first, from where, and what does each answer rule out?
2. Which of the facts above explains which symptom?
3. What do you change, in what order, and how do you verify it?
4. What goes in the record: time to detect, time to recover, and the monitoring change that would have caught it at 01:55?

<!--
Answers (accept others with the same evidence):
1. SOA from every listed server with +norec: ns2 does not answer (or answers without aa); ns1 and ns3 answer with the same serial. Then ask through the ISP's resolver if reachable, or through public resolvers: the failing ISP's resolver probably reaches ns2 first or only (its catchment or its server selection). Rules out: the whole zone is not down; the delegation is fine if the parent lists the same servers.
2. ns2's failure explains the probe alert and the one-ISP symptom (resolvers that stick to a fast but now dead server, or an anycast catchment that ends at the dead instance). The same-serial push explains nothing yet, but it is the last change: if ns2 restarted or reloaded at 01:55 it may have loaded a different file, or the change broke something only ns2 has. With the same serial the other secondaries ignored the change, so they still serve the old data: the zone now differs between servers with one serial.
3. Restore ns2's service (restart, reload the last good zone); raise the serial on the primary for the change that was pushed, so every secondary transfers it; verify with the SOA loop and the probe; ask the ISP's resolver again after the TTL.
4. Detection at 02:10, recovery when the SOA loop and the probe are green; the start was 01:55 (the push). A check that compares serials and record contents after every NOTIFY, or that refuses a change without a new serial at the primary (a pre-publication check), would have caught it at 01:55.
-->

---
<!-- _class: lab-intro -->
# Practical Lab Introduction

---
<!-- _class: dense -->
## Lab Environment

```text
 VM 1 192.0.2.30                       VM 2 192.0.2.10                          registry .53
 BIND :53 authoritative                BIND :53 resolver, :853 DoT, :443 DoH     example.
 + statistics channel 127.0.0.1:8053   + statistics channel, dnstap (11.1)
 + bind_exporter :9119 (11.2)          + Prometheus, blackbox, bind_exporter on 127.0.0.1 (11.2)
```

- **Packages:** `prometheus`, `prometheus-bind-exporter`, `prometheus-blackbox-exporter` are in the VM image with their services disabled; with a mirror: `sudo apt install --no-install-recommends` the three, then `sudo systemctl disable --now` them. `dnsperf`, `curl`, `jq`, `dnstap-read` are there already
- **Kit** `labs/module11/`: `common/`, `vm1/`, `vm2/` (configuration), `tools/` (`rates.sh`, `alerts.sh`, `zonecheck.sh`), `incident-record.md`; `instructor/` is the instructor's
- **Load:** only `dnsperf -Q 50 -l 10` from VM 1 to your own VM 2; probes every 15 s; nothing leaves the lab network. **Save before you change:** `sudo cp FILE FILE.m09`
- **Check first:** VM 2 must answer plain DNS on port 53 (Lab 11.1 step 1). Module 8's kit file could leave only 853 and 443 open; the fix is the `listen-on port 53` lines from the Module 8 slide
- **End state (Lab 11.4):** both VMs as Module 9 left them; `teamNN.example` two serials higher

---
<!-- _class: dense -->
## Lab 11.1: Counters, Rates and a Capture (20 min)

1. From VM 1: `dig @<VM 2> www.teamNN.example`. No answer on port 53? Add `listen-on port 53 { any; };` and `listen-on-v6 port 53 { any; };` to VM 2's options (Module 8 slide), reconfig. Both VMs: save `named.conf.local` and `named.conf.options` as `.m09`; append `common/named.conf.stats` to `named.conf.local`; `named-checkconf`; `sudo rndc reconfig`; `curl -s http://127.0.0.1:8053/json/v1/server | jq .nsstats`
2. VM 1: `sed 's/NN/<your NN>/g' vm1/names.txt > names.txt`; `seq 1 500 | sed 's/.*/u&.teamNN.example A/' > unique.txt` (your NN)
3. VM 2: `sh tools/rates.sh 10`; at the same time on VM 1: `dnsperf -s <VM 2> -d names.txt -Q 50 -l 10`. Note the latency and the hit ratio
4. The same with `unique.txt`. Which numbers moved, and why does VM 1 see the second run?
5. VM 2: `sudo rndc status | grep recursive`; what are 900 and 1000?
6. VM 2: paste `vm2/dnstap.options` inside `options { }`; check, reconfig; one `dig`; `sudo rndc dnstap -roll`; `sudo dnstap-read /var/cache/bind/dnstap.fstrm.0`. Then the saved options back, reconfig, `sudo rm /var/cache/bind/dnstap.fstrm*`

> **Checkpoint:** you can explain the two runs from the counters (hit ratio, recursions) and say what you would recommend (6A, task 3); the CQ and RQ lines read

<!--
Rehearsed 28 October 2026 (rehearse.sh 11.1.0-11.1.5d). Step 1: the harness first checks VM 2 answers on port 53 (11.1.0); Module 8's kit file (fixed in PR #17) added only the 853 and 443 lines, and with Debian's default (no listen-on) named then stops listening on port 53 (tested). Step 3: 500/500, hit ratio 99%, recursion 0.7 per second. Step 4: 500/500 NXDOMAIN, hit ratio 0%, 49.8-49.9 recursions per second, latency 6-9 times the first run (0.141-0.180 ms against 1.109-1.225 ms on the test host, six runs); VM 1 answers every miss. Step 5: "recursive clients: 0/900/1000" (soft and hard quota). Step 6: CQ 127.0.0.1 -> 127.0.0.1:53 www...; RQ -> 192.0.2.30:53 (and to the registry). The paste goes before the final "};" of the options file. Assess 6A task 3 here: the recommendation should name the hit ratio and recursions, the NSEC3 zones (no synthesis), and what the second run says about a random-subdomain flood.
-->

---
<!-- _class: dense -->
## Lab 11.2: Prometheus, Exporters and Alerts (25 min)

1. VM 1: save `/etc/default/prometheus-bind-exporter` as `.m09`; install `vm1/prometheus-bind-exporter` (your address); `sudo systemctl enable --now prometheus-bind-exporter`. From VM 2: `curl -s http://<VM 1>:9119/metrics | grep bind_up`
2. VM 2: save the three `/etc/default/prometheus*` files and `/etc/prometheus/{prometheus,blackbox}.yml` as `.m09`; install the kit's (your NN and addresses) and `dns-rules.yml`; `sudo install -m 644 /etc/bind/tls/ca.crt /etc/prometheus/team-ca.crt`
3. `promtool check config /etc/prometheus/prometheus.yml`; in the kit, `promtool test rules test/dns-rules.test.yml`; `prometheus-blackbox-exporter --config.file=/etc/prometheus/blackbox.yml --config.check`; `sudo systemctl enable --now` the three services
4. `curl -s 127.0.0.1:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job) \(.health)"'`: six up. `promtool query instant http://127.0.0.1:9090 'probe_dns_serial'` and `'bind_zone_serial'`: the same number? Days left on the certificate?
5. Test an alert: VM 1 `sudo systemctl stop named`; on VM 2 `sh tools/alerts.sh` every 15 s (exit 2: Prometheus did not answer, so you know nothing): pending, then firing. Start `named`; time both

> **Checkpoint:** six targets up; the probe's and the counter's serial agree; one alert fired and cleared, and you know why it took as long as it did (6A, task 1)

<!--
Rehearsed (11.2.1-11.2.5b). Step 1: bind_up 1, bind_zone_serial{zone_name="team01.example"}. Step 3: "SUCCESS: 6 rules found", the rule tests "SUCCESS" (every rule fires on its test data, including ResolverServfailRatio, which the lab's load stays below), "Config file is ok". Step 4: bind 127.0.0.1:9119 and 192.0.2.30:9119, dns_soa 192.0.2.30, dns_resolve 192.0.2.10, dot 192.0.2.10:853, prometheus: all up; probe_dns_serial equals bind_zone_serial (they can differ for one scrape while the lab policy re-signs); cert_days 29-30 on a fresh certificate (about 28 on Day 6, made on Day 4). Step 5: firing 65-86 s after the stop, cleared 14-29 s after the start (six rehearsal runs, rndc stop instead of systemctl). The web page: ssh -L 9090:127.0.0.1:9090 to VM 2, then http://localhost:9090/alerts. Assess 6A task 1 after Lab 11.3, before the clean-up.
-->

---
<!-- _class: dense -->
## Lab 11.3: Checks Across Servers and the Parent (10 min)

1. Read `tools/zonecheck.sh`: where does it get the server list, and what does it ask each server?
2. VM 2: `sh tools/zonecheck.sh teamNN.example 192.0.2.53 192.0.2.10 1200 600; echo $?` (lab signatures: warn at 20, critical at 10 minutes left)
3. `sh tools/zonecheck.sh manualNN.example 192.0.2.53 192.0.2.10; echo $?`: how many days are left on the zone you signed by hand in Lab 7.1, and what happens on that day?
4. Run it again with a warning threshold longer than the days left: which exit code, and what would a scheduler do with it?
5. In a second SSH session, leave `watch -n 60 sh tools/zonecheck.sh teamNN.example 192.0.2.53 192.0.2.10 1200 600` running for Lab 11.4

> **Checkpoint:** OK for both zones, the expiry date of `manualNN.example` stated, and the difference between this check and the probes explained (6A, task 1)

<!--
Rehearsed (11.3.1-11.3.3). Step 2: "ZONECHECK OK: team01.example, 1 server(s) at the parent, 1 in the zone", SOA and DNSKEY signatures with 24-30 minutes left, "DS ... matches a DNSKEY in the zone", exit 0. Step 3: 29-30 days in the rehearsal (signed minutes earlier); on Day 6 about 28 days (signed on Day 4); nothing re-signs it, so on that day it goes bogus. Step 4: WARNING, exit 1; thresholds that are not seconds ("7d") give UNKNOWN, exit 3. Which checks the probes could make is the Lab 11.4 debrief question (fault 2): the probes check a fixed list of addresses; zonecheck derives the list from the parent and the zone and compares across them (NS sets, glue, DS). Assess 6A task 1 for each team during Labs 11.2-11.3, before the Lab 11.4 clean-up.
-->

---
<!-- _class: dense -->
## Lab 11.4: Incident Drill and Clean-Up (35 min)

The instructor breaks something three times, one fault at a time for every team at once, and gives you only a symptom. For each:

1. Note the time (`date -u`). Evidence before any change: the alerts, `zonecheck.sh`, `dig` through VM 2 (with and without `+cd`), each server with `+norec`, the registry, the logs on both VMs
2. Name the cause and show the instructor the output that proves it and what ruled the other causes out
3. Fix it (or, if the fix is outside your VMs, send the request to whoever can act on it); verify with the same commands; time the alert clearing
4. Fill in one `incident-record.md` per fault (fault 2's is short: cause, why no alert fired, the check that caught it); finish them by the end of Day 6
5. Clean up: stop and disable the three Prometheus services (VM 2) and the exporter (VM 1); every `.m09` file back; delete `dns-rules.yml`, `team-ca.crt`, `/var/lib/prometheus/metrics2/*`; reconfig both VMs; `ss -lntup`: only `named`

> **Checkpoint:** each fault explained from evidence, fixed and verified; three incident records handed in; both VMs as Module 9 left them (6A, tasks 2 and 4)

<!--
The instructor sets each fault for all teams in one loop (faults 1 and 2 with labs/module11/instructor/faults.sh over SSH, fault 3 with instructor/ds-fault.sh at the registry), so the waits for alerts and caches overlap; each fault has a variant the instructor may choose; answers and grading in instructor/README.md. Debrief (5 minutes, from Lab 11.3): which of zonecheck's checks could the probes make, and why did fault 2 raise no alert? Rehearsed (11.4.1-11.4.7): fault 1 DNSProbeFailed for VM 1 and "connection refused" while VM 1's rndc status says "server is up and running"; fault 2 no alert, zonecheck "NS sets differ" and "ns2 ... status: REFUSED", ns2 in VM 1's NS RRset (VM 2's "BADKEY" and "NOTAUTH" lines for NOTIFY appear at every serial change, because Lab 6.4's also-notify with its key stays on VM 1: not evidence of the fault); fault 3 SERVFAIL through VM 2 (no EDE), +cd answers, "DS ... matches no DNSKEY", SERVFAIL 103-115 s after the wrong DS and AD 57-60 s after the fix (six runs). After the clean-up: named.conf, named.conf.local, named.conf.options byte-equal to the start on both VMs, no Prometheus process, port 53 (and 853, 443 on VM 2) only, the zone two serials higher. Module 12 starts from this state.
-->

---
<!-- _class: dense -->
## References & Resources

<div class="columns">
<div>

- RFC 1035, 1912, 1996 (NOTIFY), 5001 (NSID), 6781, 7344, 7477, 7646, 8078, 8198, 8767, 8914, 8932 (BCP 232), 9199, 9471, 9499 (BCP 219), 9975
- NIST SP 800-61 Rev. 3 (2025); NIST SP 800-34 Rev. 1 (2010)
- Google SRE book: "Monitoring Distributed Systems", "Service Level Objectives"
- ICANN Base Registry Agreement (2024), Specification 10
- ISC: BIND 9.20 ARM (statistics channel, counters, dnstap, limits); `named -C`
- Prometheus, bind_exporter 0.8.0, blackbox_exporter 0.26.0 documentation
- DNS-OARC dnsperf and resperf; dnstap.info; RIPE Atlas; Zonemaster; DNSViz
- Meta engineering (5 October 2021); Slack engineering (29 November 2021)

</div>
<div class="panel">
<h3>Commands</h3>
<pre><code>curl :8053/json/v1/server
rndc stats; rndc status
dnsperf -s IP -d FILE -Q 50 -l 10
rndc dnstap -roll
dnstap-read FILE
promtool check config FILE
promtool query instant URL Q
sh alerts.sh
sh zonecheck.sh ZONE PARENT RES
dig @srv zone SOA +norec
</code></pre>
</div>
</div>

---
<!-- _class: dense -->
## Knowledge Check

1. Your SOA probe of ns1 succeeds every 15 seconds, yet users in one country cannot resolve your zone. Name two causes the probe cannot see.
2. Why is one reading of `QryRecursion` useless, and what do you compute instead?
3. A zone's signatures are valid for 14 days and refreshed when 5 days remain. The signer died 6 days ago. Is the zone still valid, and which alerts should have fired, and when?
4. You find a DS at the parent that matches no DNSKEY. Validating users have failed for an hour. You fix the DS now. When will they recover?
5. Your team adds a fourth name server to the zone but not to your monitoring. What check would have found it, and what might it have found?
6. What are the RTO and the RPO of your hidden primary, and which other layer decides how much the RTO matters?

<!--
1. Routing or anycast: their catchment reaches another instance or none (a dead site still announced, Module 5); a filtering or broken ISP resolver; a delegation problem at the parent (NS or glue) that a direct probe of ns1 bypasses; validation failures (the probe does not validate). Probes from outside (RIPE Atlas) and checks of the parent see them.
2. It is a counter since the last restart: its value depends on uptime. Take two readings and divide the difference by the time (rates.sh, Prometheus rate()), and compare with queries per second.
3. Signatures are refreshed when under 5 days remain, so when the signer died every signature had between 5 and 14 days left (less up to 12 hours of jitter, BIND's default signatures-jitter). The first expired about 5 days (4.5 with jitter) after the failure: the zone has been bogus for about a day. An alert on time left set below the refresh point (zonecheck.sh's defaults: warn under 4 days, critical under 2) warned about 1 day after the failure and paged about 3 days after it, 2 days before the zone went bogus; a check of the signer's process should have paged 6 days ago.
4. When the corrected DS reaches the resolvers' caches: after the parent publishes it and the old DS's TTL (and the cached bad state) runs out; with a .com-style 24 h DS TTL, up to a day (Slack); in the lab about a minute. Resolver operators can flush or add a temporary NTA.
5. A check that takes the server list from the zone's NS RRset and the parent (zonecheck.sh, Zonemaster): it would find a lame server, a server with an old serial, NS sets that differ between parent and zone, or missing glue.
6. RTO: how long you can be without making changes (and, for signed zones, without re-signing) before it hurts; RPO: how many zone changes you can lose since the last backup or since the source of truth (registry database). The secondaries keep answering until EXPIRE and the signatures until they expire: those layers decide how urgent the primary's RTO is.
-->

---
<!-- _class: section-divider -->
# Thank You

---
<!-- _class: dense -->
## Contact

**Terry Sweetser** — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

---
<!-- _class: section-divider -->
# Licence

---
<!-- _class: dense -->
## Creative Commons Attribution–NonCommercial–ShareAlike 4.0

This work is licensed under a  
[Creative Commons Attribution–NonCommercial–ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

**You are free to:**
- **Share** — copy and redistribute the material
- **Adapt** — remix, transform, and build upon the material

**Under the following terms:**
- **Attribution** — credit **Terry Sweetser (IEISI.ORG)**
- **NonCommercial** — no commercial use
- **ShareAlike** — same licence on derivatives
