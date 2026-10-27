# Module 4 comparison sheet (Lab 4.4, Practical Assessment 2B)

Team: `NN` = ____  Names: ______________________  Date: __________

Fill in each cell from what you ran in Labs 4.1-4.4 (commands, output,
log lines) or from the vendor's documentation (name the page). Keep each
cell to one or two lines. Performance: write only what you measured on
your own VMs, with the set-up (date, versions, VM size, query file), or
"not measured"; no figures from vendor benchmarks.

| Question | BIND 9.20 (VM 1 and VM 2, port 53) | Unbound 1.26 (VM 2, port 5300) | PowerDNS Authoritative 4.9 (VM 1, port 5300) |
|---|---|---|---|
| Role(s) it played today | | | |
| Where its data or settings live (files, database) | | | |
| How you checked a configuration before using it | | | |
| How you applied a change (and what it cost: cache, counters) | | | |
| Control tool and one command you used | | | |
| Where you read its counters, and one value you saw | | | |
| A default that mattered today | | | |
| What it logged for a query (one line) | | | |
| Version in Debian 13, and its support status upstream (as of today) | | | |
| What surprised you | | | |

## Two answers in one sentence each

1. In Lab 4.4 step 1, Unbound and BIND gave different answers for
   `api.teamNN.example`. Why, and which server held "the" zone?

   ________________________________________________________________

2. Lab 4.4 discussion: for a zone you run at work, which of today's three
   would you choose, and what would you test before switching? (One
   minute per team, to the group.)

   ________________________________________________________________

## For the assessor (Practical Assessment 2B)

- Task 1 (8 points): the table, with each cell traceable to a lab step or
  a named document; performance cells either measured with their set-up
  or "not measured".
- Task 2 (7 points): the deck's "Which Software Where?" exercise
  (Module 4, section 6) or the instructor's own scenarios.
- Task 3 (5 points): configuration differences (the BIND and Unbound
  side-by-side slide) and migration considerations (the HTTPS import
  finding, AXFR or absolute-name import, comparing answers before moving
  the delegation).
- Task 4 (5 points): question 2 above, answered to the group in about a
  minute per team at the end of Lab 4.4.
