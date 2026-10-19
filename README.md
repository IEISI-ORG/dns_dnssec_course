# Advanced DNS/DNSSEC Workshop (Marp)

An open course for teaching **DNS, DNSSEC, privacy, and registry operations** with hands-on labs.  
Slides are built with **[Marp](https://marp.app/)** using a custom theme inspired by ICANN’s design language.  
**License:** CC BY-NC-SA 4.0 (non-commercial, attribution, share-alike)

**Maintainer:** Terry Sweetser (IEISI.ORG) — <tcs@ieisi.org>

---

## Status

Early stage. The course design is in the planning documents. The 12 module decks are skeletons, all generated from one template, and are waiting for content.

---

## What’s inside

- **Planning documents** (the course content, for now):
  - `dns_dnssec_workshop_plan.md` — programme facts, module objectives, and lab appendix (the reference document)
  - `dns_slide_deck_plan.md` — a slide-by-slide outline for each module
  - `dns_assessment_plan.md` — daily assessments and the final project
  - `dns_workshop_scope.md` — the one-page scope and delivery options
- **Decks:**
  - `modules/module01…12-*.marp.md` — one skeleton deck per module
  - `dns_deck_overview.md` — overview / briefing deck
  - `dns-workshop-demo-presentation.md` — a full example deck showing the theme
- **Theme:** `dns-workshop-css-theme.css` (theme name `ieisi-dns-workshop`)
- **Style guide:** `dns-workshop-marp-style.md` — front matter, slide classes, and HTML helpers
- **Build:** `Makefile` (all decks) and `test-html` (one deck, opened in the browser)

---

## Quick start

### 1) Clone and install Marp CLI
```bash
git clone https://github.com/IEISI-ORG/dns_dnssec_course.git
cd dns_dnssec_course
npm i -g @marp-team/marp-cli
```
PDF output also needs Chrome, Chromium, or Edge.

### 2) Preview in VS Code
- Install the **Marp for VS Code** extension.
- Add to `.vscode/settings.json`:
  ```json
  "markdown.marp.themes": ["./dns-workshop-css-theme.css"],
  "markdown.marp.enableHtml": true
  ```
- Open a deck (e.g. `modules/module01-dns-foundations.marp.md`) and toggle the Marp preview.

### 3) Build from the CLI
```bash
make html        # all decks → dist/*.html
make pdf         # all decks → dist/*.pdf
./test-html modules/module01-dns-foundations.marp.md   # one deck, opens in browser
```

**Front matter (copy into every deck):**
```yaml
---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
---
```

**Per-slide class:**
```markdown
---
<!-- _class: section-divider -->
# Module Overview
```
With the underscore, `_class` styles only that slide. Without it, `class` also applies to every slide that follows.
For the full list of classes, see `dns-workshop-marp-style.md`.

---

## Repository structure

```
.
├─ modules/                          # 12 module decks (skeletons)
├─ dns_dnssec_workshop_plan.md       # programme and lab plan
├─ dns_slide_deck_plan.md            # slide outlines
├─ dns_assessment_plan.md            # assessments
├─ dns_workshop_scope.md             # scope summary
├─ dns_deck_overview.md              # overview deck
├─ dns-workshop-demo-presentation.md # example deck
├─ dns-workshop-css-theme.css        # Marp theme
├─ dns-workshop-marp-style.md        # theme usage guide
├─ Makefile                          # build all decks to dist/
├─ test-html                         # build + open one deck
├─ LICENSE.md
└─ README.md
```

---

## Theming & accents

- Theme: **`ieisi-dns-workshop`** (ICANN-inspired palette).
- Per-slide accent classes: `accent-icann`, `accent-teal`, `accent-blue`, `accent-cyan`, `accent-violet`, `accent-emerald`, `accent-slate`.

Example:
```markdown
---
<!-- _class: lab-intro accent-icann -->
# Practical Lab Introduction
```

Layout helpers: `dense`, `compact`, `compact-list`, `table-compact`, `grid-2`, `grid-3`, and the inline `<div class="columns">` and `<div class="panel">`.

---

## Contributing 🤝

Contributions are very welcome: issues, ideas, forks, and PRs.

### Ways to help
- **Content:** expand slides, add examples, improve labs
- **Accuracy:** fix technical errors, add RFC references
- **Design:** refine the theme, improve readability and accessibility
- **Automation:** add CI to build the decks

### How to contribute
1. **Fork** the repo and create your branch:
   ```bash
   git checkout -b feature/module07-key-rollover-lab
   ```
2. **Edit decks** in `modules/` or the theme `dns-workshop-css-theme.css`.
3. **Build locally** to verify:
   ```bash
   make dist/module07-dnssec-implementation.marp.pdf
   ```
4. **Commit** with a clear message:
   ```bash
   git commit -m "feat(module07): add DNSSEC rollover lab steps"
   ```
5. **Push** and open a **Pull Request**.  
   Describe the change and why you made it, and add screenshots for visual changes.

### Guidelines
- Keep slides concise; split long content across slides.
- Use per-slide class directives (`<!-- _class: ... -->`) for styling.
- Prefer reproducible examples (e.g. `dig`, `named-checkzone`).
- Respect the license (non-commercial, share-alike).
- Be respectful in discussions.

---

## Issues & discussions

- **Issues:** bug reports, enhancement requests, or questions
- **Discussions:** ideas, teaching tips, lab improvements, success stories

Please search before filing a new issue to avoid duplicates.

---

## License

This project is licensed under the **Creative Commons Attribution–NonCommercial–ShareAlike 4.0 International** license (see `LICENSE.md`).

You are free to **share** and **adapt** the material with **attribution**, for **non-commercial** use, and you must **share alike**.

Full text: https://creativecommons.org/licenses/by-nc-sa/4.0/

**Attribution:** Terry Sweetser (IEISI.ORG)

---

## Acknowledgements

- Community curricula and best practices across DNS operations and security
- Visual inspiration: ICANN design language
- Thanks to contributors and reviewers for improving accuracy and clarity

---

## Contact

**Terry Sweetser** — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

If you use these materials or build on them, I’d love to hear about your experience. Please share it via issues or discussions.
