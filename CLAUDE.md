# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A reusable [Quarto](https://quarto.org) **report template** that renders from Markdown/Quarto source to **two outputs from one source**: a PDF (via the Typst engine) and an HTML website (deployable to GitHub Pages). There is no application code; the "source" is prose, figures, and a custom styling layer. `README.md` is the user-facing guide and includes an *effect → syntax → file* lookup table — consult it when asked how to produce a specific visual effect.

## Build, preview & test

```bash
quarto preview                       # live-reloading local HTML preview while editing
quarto render                        # render all formats (HTML → _site/, plus _site/index.pdf)
quarto render index.qmd --to html    # HTML only
quarto render index.qmd --to typst   # PDF only
bash test/render-test.sh             # render both formats + assert invariants (add --keep to retain output)
```

Rendering the PDF requires Typst (bundled with recent Quarto). Output goes to `_site/`; `_site/`, `index.pdf`, `index.typ` are gitignored build artifacts — do not hand-edit them.

## CI/CD

`.github/workflows/render-report.yaml`: pull requests run `bash test/render-test.sh` (the gate — see Testing); pushes to `main` render and deploy `_site/` to GitHub Pages via OIDC. The workflow assumes this template is the **repository root**.

## Testing

`test/render-test.sh` is a dependency-free bash smoke test. A bare `quarto render` only proves the build didn't crash; it can still emit a PDF that silently dropped a component if the `inline.lua` → `style.typ` mapping breaks. The test renders both formats and asserts: every custom class appears in the HTML, the native constructs render, the **PDF** received the Typst function calls (checked against the intermediate `index.typ`), the PDF is valid, and no cross-references or citations are unresolved. **When you add a component, add its HTML class to `CUSTOM_CLASSES` and its Typst call to `TYPST_CALLS` in the script**, or the test won't cover it.

## Architecture

**Document assembly.** `index.qmd` is the root. It holds the *entire* Quarto config in its YAML front matter (formats, themes, fonts, bibliography) — `_quarto.yml` only sets `output-dir: _site`. It also hand-builds the cover (a full-bleed Typst title page for the PDF, a `.hero-banner` for HTML). The body is thin: section headers followed by `{{< include _section.qmd >}}` pulling in per-section partials (`_summary`, `_components`, `_media`, `_tables_math`, `_native`, `_acknowledgements`). **Edit content in the partials, not `index.qmd`.**

**Dual-format is the core constraint.** Everything must work in both Typst (PDF) and HTML. Two mechanisms handle format divergence:

1. **Conditional blocks** — `::: {.content-visible when-format="typst"}` vs `when-format="html"`. Used for the cover, the light/dark image swap, and iframes (HTML-only, with a static PDF fallback).

2. **Custom components via `inline.lua`** — a Pandoc filter that, for Typst output, rewrites custom classes into Typst function calls; for HTML it leaves them for `styles.css`. So `::: {.custom-card .positive-theme}` becomes `#CustomCard("positive")[...]` in the PDF and a styled div on the web. Handled classes: `.custom-card` (+ `.anchor-theme`/`.positive-theme`/`.negative-theme`), `.quiz-card`, `.mcq-option` (+ `.correct`), `.prompt-box`, `.algorithm-box`, `.research-question-box`, and inline spans `.orange-badge`, `.subtext`, `.quiz-tag`, `.label-orange`/`.label-blue`/`.label-dark`. Inline `` `code` `` is also rewritten (`#InlineCode`).

**Styling lives in three coordinated files** — keep them in sync:
- `style.typ` — Typst function definitions (`InlineCode`, `CustomCard`, `QuizCard`, `PromptBox`, `algorithm-box`, `researchbox`, …) plus heading/link/table styling. Included via `include-in-header`.
- `layout.typ` — Typst document-level setup (paragraph, code-block, figure, math sizing). Included via `include-before-body`.
- `styles.css` — the HTML equivalent, with light/dark theming driven by CSS variables.

**The golden rule for adding a component:** touch four places with the same class name — a branch in `inline.lua`, a function in `style.typ`, a rule in `styles.css`, and the two lists in `test/render-test.sh`.

## Conventions & gotchas

- **Source formatting is handled by [Panache](https://panache.bz)** — a Pandoc/Quarto-aware formatter + linter. Config is in `panache.toml` (`wrap = "semantic"` → one sentence per line, capped at `line-width = 120`). It runs as a pre-commit hook (`.pre-commit-config.yaml`, auto-formats staged `.qmd`/`.md`) and can be run by hand: `panache format .` / `panache format --check .`. **Do *not* use a generic CommonMark formatter (mdformat, Prettier)** — they corrupt Quarto syntax: escaping `$…$` math (`\eta` → `\\eta`), rewriting `---` dividers, escaping `layout` attributes, and mangling `:::` fences and raw ` ```{=typst} `/` ```{=html} ` blocks. Panache parses the Pandoc CST instead, preserving `\` hard breaks, math, and raw blocks (verified: reformatting the whole project leaves the rendered Typst byte-identical). Wrapping is purely cosmetic anyway — Pandoc joins soft-wrapped lines within a paragraph into spaces — and correctness stays gated by `test/render-test.sh`.
- **Heading levels in Typst are positional, not absolute.** `style.typ` maps heading *appearance order* to levels — if you skip `#` and start at `##`, that `##` is styled as level 1. Keep the hierarchy consistent.
- **Citations:** `bibliography` (`references.bib`) is set at the document level so both formats cite; `csl` (IEEE) is set **HTML-only** because Typst cannot open a remote CSL URL and would error — the PDF uses Typst's built-in numeric style. References render under `# References` via `::: {#refs}`.
- **Assets** live in `assets/`; fonts (Inter, Roboto, Roboto Mono) are in `assets/fonts/` and loaded via `font-paths` (used at PDF-compile time). Only *referenced* assets are copied into the HTML output. The logo ships in two variants (`logo.svg` brand, `logo-white.svg` for dark backgrounds); other images are generic placeholders — swap them.
- **Dark mode:** HTML has light/dark themes; images use `.auto-invert`, `.light-island`, or a `.light`/`.dark` two-file swap. The PDF is single-mode.
