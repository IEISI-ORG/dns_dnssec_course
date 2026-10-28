# Module 5 instructor files: the Lab 5.4 troubleshooting drill

`faults.sh` sets one fault at a time in a team's anycast lab (Labs 5.3-5.4,
`../anycast/anycast-lab.sh`). Participants do not run it: the instructor does,
on the team's VM 2, while the lab is up:

```sh
ssh <team VM 2> 'sudo sh -s -- 2' < labs/module05/instructor/faults.sh
```

It needs no other kit file on the VM. The team then finds the cause from
evidence, tells the instructor, and undoes it with
`sudo sh anycast/anycast-lab.sh fix`, which restores both sites' zones, BIRD
configurations, `named` and health checks and waits until each router forwards
to its own site again.

**This repository is public.** Anyone can read this file and the script, so
the drill is graded on the evidence and the method (Practical Assessment 3A
task 4 in `dns_assessment_plan.md`): which commands the team ran, in which
order, what each showed, and how that rules causes in or out. Naming the
cause alone earns little. Set the faults in an order of your choosing and do
not say which one is set.

## Faults and what a team should find

| Fault | What `faults.sh` does | Symptom to give the team | Evidence that shows the cause |
|---|---|---|---|
| 1 | site B's zone replaced by an older one (serial 2026102701, `www` 198.51.100.81), `named` reloaded with SIGHUP | "City 2 gets an old address for `www.svc.test`" | `dig +nsid` from C2 answers `site-b` with .81, from C1 `site-a` with .80; the SOA at each site's own address: 2026102801 at 198.51.100.6, 2026102701 at .14 |
| 2 | site A's health check stopped, then its `named` | "Nobody in city 1 can resolve" | C1: "connection refused"; C2 fine; `status`: R1 still forwards via 198.51.100.6, site A "named stopped, health check stopped"; site A's health log has no "withdrawn" line after its last start |
| 3 | site A's export filter prepends AS 65100 twice, `birdc configure` | "City 1 is answered from far away" | `dig +nsid` from C1 answers `site-b`; `status`: R1's path via site A is `65100 65100 65100`, longer than `65002 65100` via R2, so R1 forwards via 198.51.100.10 |

A good method (any order that gathers the same evidence is fine): ask from
both cities with `+nsid`; ask each site's own address for the SOA; read
`status` (sessions, paths, forwarding, process state); read the health logs;
only then change something.

Fault 2's lesson is the health check itself: it died with the server, so
nothing withdrew the route. In production it runs supervised, apart from the
server, and an alarm fires when it stops. Fault 3 is what an operator does on
purpose to move traffic (RFC 9199 C4), left in place by mistake.

## Tested

`../test/rehearse.sh` steps 5.4.1-5.4.6 pipe this script into the stand-in
VM 2 (`sh -s -- N`, as over SSH), check each symptom and the evidence, and
check that `fix` brings back both health checks and the normal routes.
