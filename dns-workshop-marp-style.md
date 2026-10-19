# DNS Workshop Marp Style Guide

How to use the workshop theme, `dns-workshop-css-theme.css` (theme name `ieisi-dns-workshop`).
For a full example deck, see `dns-workshop-demo-presentation.md`.

## 1. Front matter

```yaml
---
marp: true
theme: ieisi-dns-workshop
paginate: true
footer: "IEISI.ORG • CC BY-NC-SA 4.0 • tcs@ieisi.org"
---
```

The `theme:` value must match the `/* @theme ieisi-dns-workshop */` line at the top of the CSS.
If it doesn't, Marp silently falls back to its default theme.

## 2. VS Code preview

Add to `.vscode/settings.json` (or your user settings):

```json
{
  "markdown.marp.themes": ["./dns-workshop-css-theme.css"],
  "markdown.marp.enableHtml": true
}
```

## 3. Slide classes

Set a class on one slide with `<!-- _class: name -->` (with the underscore).
Without the underscore, `<!-- class: name -->` applies to that slide **and every slide after it**.
Combine classes with spaces: `<!-- _class: dense accent-violet -->`.

| Class | Effect |
|---|---|
| `title-slide` | Blue gradient, centred title and subtitle |
| `section-divider` | Accent gradient, centred heading for module or section breaks |
| `lab-intro` | Green gradient for practical exercise introductions |
| `dense` | Smaller text and padding for wordy slides |
| `compact` | Tighter padding at base font size |
| `tight` | Less space around headings |
| `compact-list` | Tighter list spacing |
| `table-compact` | Tighter table cell padding |
| `no-footer` | Hide the footer on this slide |
| `alt-bg`, `blue-wash` | Light background variants |
| `grid-2`, `grid-3` | Make the whole slide a 2- or 3-column grid (each element is a cell) |
| `accent-teal`, `accent-cyan`, `accent-blue`, `accent-violet`, `accent-emerald`, `accent-slate`, `accent-icann` | Change the accent colour pair |

## 4. Inline HTML elements

These need HTML enabled (`--html` on the CLI, `enableHtml` in VS Code).

| Markup | Effect |
|---|---|
| `<div class="columns">…</div>` | Two-column layout inside a slide (leave a blank line after the opening tag of each column so Markdown renders) |
| `<div class="columns-3">…</div>` | Three-column layout |
| `<div class="panel">…</div>` | Light card with shadow |
| `<span class="highlight">text</span>` | Accent-coloured highlight |
| `<span class="badge">Label</span>` | Small pill label |
| `<div class="warning">…</div>`, `success`, `error` | Callout boxes |

## 5. Building

Use the `Makefile` at the repo root (`make html`, `make pdf`) or `./test-html <deck.md>` for a single deck.
To run marp by hand:

```bash
marp --theme-set dns-workshop-css-theme.css --html --allow-local-files --pdf deck.md
```
