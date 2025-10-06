# Advanced DNS/DNSSEC Workshop (MARP)

A complete, open course for teaching **DNS, DNSSEC, privacy, and registry operations** with hands-on labs.  
Built in **[Marp](https://marp.app/)** using a custom theme inspired by ICANN’s design language.  
**License:** CC BY-NC-SA 4.0 (non-commercial, attribution, share-alike)

**Maintainer:** Terry Sweetser (IEISI.ORG) — <tcs@ieisi.org>

---

## What’s inside

- **12 module decks** (skeletons ready to fill):
  - Module 1: DNS Foundations … Module 12: Emerging Technologies
- **Custom themes** (`themes/`):  
  `dns-workshop-css-theme.css` (ICANN-inspired default), plus accent-switchable variants
- **Overview deck** for marketing/briefing
- **Utilities & examples**: per-slide classes (`section-divider`, `lab-intro`, `dense`, `grid-2`, etc.)

> **Note on Marp behavior:** Newer Marp builds require **class directives per slide**.  
> Use `<!-- _class: section-divider -->` (underscore) at the top of any slide needing a style.

---

## Quick start

### 1) Clone and install Marp CLI
```bash
git clone https://github.com/<you>/<repo>.git
cd <repo>
npm i -g @marp-team/marp-cli
```

### 2) Preview in VS Code (recommended)
- Install the **Marp for VS Code** extension
- In **settings.json** add:
  ```json
  "markdown.marp.themes": ["./themes/ieisi-dns-workshop-icann.css"]
  ```
- Open a deck (e.g., `modules/module01-dns-foundations.marp.md`)  
  and toggle the Marp preview.

### 3) Build from CLI
```bash
# PDF
marp modules/module01-dns-foundations.marp.md \
  --theme ./themes/ieisi-dns-workshop-icann.css \
  --allow-local-files --html \
  -o dist/module01.pdf

# PowerPoint (not recommended)
marp modules/module01-dns-foundations.marp.md \
  --theme ./themes/ieisi-dns-workshop-icann.css \
  --allow-local-files --html \
  -o dist/module01.pptx
```

**Front-matter template (copy into every deck):**
```yaml
---
marp: true
theme: ieisi-dns-workshop
paginate: true
html: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
---
```

**Per-slide class (required by newer Marp):**
```markdown
---
<!-- _class: section-divider accent-icann -->
# Module Overview
```

---

## Repository structure

```
.
├─ modules/
│  ├─ module01-dns-foundations.marp.md
│  ├─ module02-dns-operations.marp.md
│  └─ ... (up to module12)
├─ overview/
│  └─ dns-overview-deck.marp.md
├─ themes/
│  ├─ ieisi-dns-workshop-icann.css      # ICANN-inspired default
│  ├─ ieisi-dns-workshop.css            # base theme
│  └─ ieisi-dns-workshop-accent.css     # accent-switchable
├─ assets/                               # images, logos, diagrams
├─ .github/
│  ├─ ISSUE_TEMPLATE/                    # (optional) issue templates
│  └─ PULL_REQUEST_TEMPLATE.md           # (optional) PR template
└─ README.md
```

---

## Theming & accents

- Default theme: **`ieisi-dns-workshop`** (ICANN-inspired palette).
- Per-slide accent classes: `accent-icann`, `accent-blue`, `accent-cyan`, `accent-violet`, `accent-emerald`, `accent-slate`.

Example:
```markdown
---
<!-- _class: lab-intro accent-icann -->
# Practical Lab Introduction
```

Layout helpers: `dense`, `compact-list`, `table-compact`, `grid-2`, `grid-3`, `panel`.

---

## Contributing 🤝

Contributions are very welcome—issues, ideas, forks, and PRs!

### Ways to help
- **Content:** expand slides, add examples, improve labs
- **Accuracy:** fix technical errors, add RFC references
- **Design:** refine theme, improve readability/accessibility
- **Automation:** add build scripts, GitHub Actions, or Makefile

### How to contribute
1. **Fork** the repo and create your branch:
   ```bash
   git checkout -b feature/module07-key-rollover-lab
   ```
2. **Edit decks** in `modules/` or theme in `themes/`.
3. **Build locally** to verify:
   ```bash
   marp modules/module07-dnssec-implementation.marp.md \
     --theme ./themes/ieisi-dns-workshop-icann.css \
     --allow-local-files --html -o dist/module07.pdf
   ```
4. **Commit** with a clear message:
   ```bash
   git commit -m "feat(module07): add DNSSEC rollover lab steps"
   ```
5. **Push** and open a **Pull Request**.  
   Please describe the change, rationale, and screenshots (if visual).

### Guidelines
- Keep slides concise; split long content across slides.
- Use per-slide class directives (`<!-- _class: ... -->`) for styling.
- Prefer examples that are reproducible (e.g., `dig`, `bind9-utils`).
- Respect the license (non-commercial, share-alike).
- Be respectful in discussions (see Code of Conduct below).

---

## Issues & discussions

- **Issues:** Bug reports, enhancement requests, or questions
- **Discussions:** Ideas, teaching tips, lab improvements, success stories

Please search before filing a new issue to avoid duplicates.

---

## License

This project is licensed under the **Creative Commons Attribution–NonCommercial–ShareAlike 4.0 International** license.

You are free to **share** and **adapt** the material with **attribution**, for **non-commercial** use, and you must **share alike**.

Full text: https://creativecommons.org/licenses/by-nc-sa/4.0/

**Attribution:** Terry Sweetser (IEISI.ORG)

---

## Acknowledgements

- Community curricula & best practices across DNS operations and security
- Visual inspiration: ICANN design language
- Thanks to contributors and reviewers for improving accuracy and clarity!

---

## Contact

**Terry Sweetser** — <tcs@ieisi.org>  
**Organisation:** IEISI.ORG

If you use these materials or build on them, I’d love to hear about your experience—please share via issues or discussions!
