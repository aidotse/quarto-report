# Dual-Format Quarto Report Template

A self-contained starter for reports that render from **one Markdown source** to
**both** a print-ready **PDF** (via the [Typst](https://typst.app) engine) and a
themeable **HTML** site with working light/dark mode.
It packages the mechanics
worked out in a real project report as a reusable reference: cards, callout-style
boxes, badges, dark-mode-aware images, light/dark artwork swaps, embedded iframes,
tables, math, and code --- each styled identically across PDF and web.

## Quick start

```bash
# from this folder (or copy it to a new project first)
quarto preview            # live HTML preview while editing
quarto render             # build everything -> _site/ (HTML) + index.pdf
quarto render index.qmd --to html    # HTML only
quarto render index.qmd --to typst   # PDF only
```

Requires a recent [Quarto](https://quarto.org) (Typst ships with it).
Fonts are
bundled in `assets/fonts/`, so the PDF is reproducible without system fonts.

To start a new report: edit the cover in `index.qmd` (title/subtitle/author, in
**both** the `typst` and `html` branches), replace the placeholder assets in
`assets/`, and edit/replace the `_*.qmd` section partials.

## How it fits together

  | File                                   | Role                                                                                                                                                                               |
  | :------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `index.qmd`                            | Root document: all config (front matter), the dual cover (Typst page / HTML hero), and `{{< include _*.qmd >}}` of each section.                                                   |
  | `_quarto.yml`                          | Minimal project config (`output-dir: _site`).                                                                                                                                      |
  | `inline.lua`                           | Pandoc filter. For the **PDF** it rewrites custom classes into Typst function calls; for **HTML** it leaves them for the CSS.                                                      |
  | `style.typ`                            | PDF: component functions (`CustomCard`, `PromptBox`, …) + type/heading/link styling. Injected via `include-in-header`.                                                             |
  | `layout.typ`                           | PDF: document-level setup (code blocks, figures, math sizing). Injected via `include-before-body`.                                                                                 |
  | `styles.css`                           | HTML: theme variables (light/dark), typography, and every custom-component class.                                                                                                  |
  | `references.bib`                       | Sample bibliography (IEEE CSL). Cite with `[@example2025]`; rendered under `# References`.                                                                                         |
  | `assets/`                              | Images + bundled fonts. Assets referenced from the document or from CSS `url()` are copied into the output automatically; fonts are consumed at PDF-compile time via `font-paths`. |
  | `_*.qmd`                               | Section partials, each a live gallery of one topic (`_components`, `_media`, `_tables_math`, `_native`, `_acknowledgements`, `_summary`).                                          |
  | `.github/workflows/render-report.yaml` | GitHub Actions: smoke-test on PRs, deploy `_site/` to GitHub Pages on push to `main` (see [Deploying](#deploying)).                                                                |
  | `test/render-test.sh`                  | Dependency-free smoke test: renders both formats and asserts the template invariants (see [Testing](#testing)).                                                                    |

**The golden rule for a new component:** add it in four places with the same
class name --- a branch in `inline.lua`, a function in `style.typ`, a rule in
`styles.css`, and its class/Typst call in the `test/render-test.sh` lists (so the
test actually covers it).

## Effect → how to do it

  | Effect                                 | Syntax                                                            | Shown in                                     |
  | :------------------------------------- | :---------------------------------------------------------------- | :------------------------------------------- |
  | PDF title page / HTML hero banner      | `::: {.content-visible when-format="typst"}` vs `="html"`         | `index.qmd`                                  |
  | Format-specific content (anything)     | `::: {.content-visible when-format="html"}`                       | `index.qmd`, `_media.qmd`                    |
  | Executive summary                      | plain prose under `## Executive Summary`                          | `_summary.qmd`                               |
  | Styled inline code                     | `` `like this` `` (auto-tagged by `inline.lua`)                   | `_components.qmd`                            |
  | Orange badge / subtext                 | `[x]{.orange-badge}` · `[x]{.subtext}`                            | `_components.qmd`                            |
  | Monospace labels                       | `[x]{.label-orange \| .label-blue \| .label-dark}`                | `_components.qmd`                            |
  | Prompt / callout box                   | `::: {.prompt-box}`                                               | `_components.qmd`                            |
  | Outlined question box                  | `::: {.research-question-box}`                                    | `_components.qmd`                            |
  | Algorithm / pseudocode box             | `::: {.algorithm-box}` (line breaks with `\`)                     | `_components.qmd`                            |
  | Data cards (blue/green/red)            | `::: {.custom-card .positive-theme}`                              | `_components.qmd`                            |
  | Side-by-side columns                   | `::: {layout-ncol="3"}` or `layout="[[45, 55]]"`                  | `_components.qmd`, `_acknowledgements.qmd`   |
  | Quiz card + MCQ options                | `::: {.quiz-card}` + `::: {.mcq-option .correct}`                 | `_components.qmd`                            |
  | Numbered figure (any content)          | wrap in `::: {#fig-name}` … `:::`                                 | `_components.qmd`, `_media.qmd`              |
  | Rounded-corner image                   | `![](x.png){.img-rounded}`                                        | `_media.qmd`                                 |
  | Invert image in dark mode              | `![](x.png){.auto-invert}`                                        | `_media.qmd`                                 |
  | Light "island" in dark mode            | `![](x.png){.light-island}`                                       | `_media.qmd`                                 |
  | Light/dark artwork swap                | two images tagged `.light` and `.dark`                            | `_media.qmd`                                 |
  | Embedded iframe (+ PDF fallback)       | HTML `<iframe>` in a `when-format="html"` block                   | `_media.qmd`                                 |
  | Absolute-width / aligned image         | `![](x.svg){width="4cm" fig-align="left"}`                        | `_media.qmd`                                 |
  | Simple / complex tables                | pipe tables + `{tbl-colwidths="[...]"}` + inline `[x]{style=...}` | `_tables_math.qmd`                           |
  | Inline / display math                  | `$...$` and `$$...$$`                                             | `_tables_math.qmd`                           |
  | Highlighted code block                 | fenced ```` ```python ```` block                                  | `_tables_math.qmd`                           |
  | Multi-column acknowledgements          | `::: {layout="[[55, 2, 45]]"}` with named sub-columns             | `_acknowledgements.qmd`                      |
  | Page break (PDF) / section break (web) | `{{< pagebreak >}}`                                               | `index.qmd`                                  |
  | Author / bio strip (HTML only)         | `.author-box` + `.divider-line`                                   | `_components.qmd`                            |
  | Citations / references (+ styles)      | `[@key]` + `::: {#refs}:::` + `csl:`                              | `_native.qmd`, `index.qmd`, `references.bib` |

### Native Quarto constructs

These are built into Quarto (not part of the custom styling layer):

  | Effect                                             | Syntax                                                        | Shown in      |
  | :------------------------------------------------- | :------------------------------------------------------------ | :------------ |
  | Callout boxes (note/tip/warning/important/caution) | `::: {.callout-note}` (+ `collapse=`, `appearance=`, `icon=`) | `_native.qmd` |
  | Tabsets                                            | `::: {.panel-tabset}` with `##` tabs                          | `_native.qmd` |
  | Margin content                                     | `::: {.column-margin}` and `[^footnote]`                      | `_native.qmd` |
  | Citations & bibliography (styles, `.bib`, `#refs`) | `[@key]`, `@key`, `[@key, p. 5]` + `csl:`                     | `_native.qmd` |

## Formatting & pre-commit hooks

Source formatting is handled by [Panache](https://panache.bz), a Pandoc/Quarto-aware
formatter + linter (config in `panache.toml`: one sentence per line, wrapped at 120
columns).
Do **not** use mdformat or Prettier --- they are CommonMark tools that corrupt
Quarto syntax (escaping `$…$` math, mangling `:::` fences and raw Typst/HTML blocks).

```bash
# one-time, after cloning:
uv tool install pre-commit        # or: pipx install pre-commit
pre-commit autoupdate             # pin the current Panache hook version
pre-commit install --hook-type pre-commit --hook-type pre-push
pre-commit run --all-files        # optional: check the whole repo now
```

This wires two tiers of checks (see [Testing](#testing) for the render test):

- **on every commit** --- `panache format` (auto-formats staged `.qmd`/`.md`) and
  `panache lint` (broken references, heading hierarchy).
  Milliseconds.
- **on every push** --- the full `test/render-test.sh` dual-format render, as a local
  safety net that catches a broken render before it reaches CI.

To run the formatter by hand, install the CLI once (`uv tool install panache-cli`),
then `panache format .` (or `panache format --check .` to verify without writing).
The commit hook does not need this --- pre-commit fetches its own pinned Panache.
The pre-push render test is local convenience and bypassable
(`git push --no-verify`); the authoritative gate is the same test run as a required
status check on `main` (see [Deploying](#deploying)).

## Testing

```bash
bash test/render-test.sh          # render both formats + assert invariants
bash test/render-test.sh --keep   # keep _site/ and index.typ afterwards
```

A plain `quarto render` only tells you the build didn't crash --- it will happily
emit a PDF that silently dropped a component if the `inline.lua` → `style.typ`
mapping breaks.
This dependency-free bash smoke test guards that seam.
It renders
to HTML and PDF and checks that:

- both formats render without error and the PDF is a valid file with a sane page count;
- every custom class (from `inline.lua` / `styles.css`) actually appears in the HTML;
- the native Quarto constructs (callouts, tabset, margin) render;
- the **PDF** received the Typst function calls (`#CustomCard`, `#PromptBox`, callouts, ...) --- verified against the intermediate `index.typ`;
- there are no unresolved cross-references or citations, and the bibliography populated.

It exits non-zero on any failure, so it doubles as the CI gate on pull requests.
**When you add a component**, add its HTML class to `CUSTOM_CLASSES` and its Typst
call to `TYPST_CALLS` in the script.

## Deploying

`.github/workflows/render-report.yaml` renders the report in CI and publishes the
HTML site to GitHub Pages.
The workflow assumes the template is the **repository
root**, so:

1. Copy the contents of `template/` into a new repository (the workflow file comes
   along under `.github/workflows/`).
2. In the repo settings, set **Pages → Build and deployment → Source** to
   *GitHub Actions*.
3. Push to `main`.
   PRs get a build-only check; pushes to `main` render and deploy.

**Protecting `main`:** enable *Settings → Branches → Add rule for `main` → "Require status checks to pass before merging"* and select the `test-build` check, so breaking code can't be merged.

The `index.qmd` sidebar links to `index.pdf`, which the same `quarto render`
produces into `_site/`, so the PDF is downloadable from the published site.

## Gotchas

- **Typst heading levels are positional**, not absolute (see `style.typ`): the
  first heading that appears becomes "level 1" styling regardless of how many `#`
  it has.
  Keep your heading hierarchy consistent.
- **Edit the cover text in both branches** of `index.qmd` --- the Typst page and the
  HTML hero are independent.
- **Fonts** are bundled; `style.typ` uses Roboto + Roboto Mono.
  Inter is also in
  `assets/fonts/` if you prefer it (see the commented line in `style.typ`).

## Notes on this template's defaults

Two choices were made when generating this template; both are easy to change:

1. **Branding:** the logo is the **AI Sweden** wordmark, shipped in two variants ---
   `logo.svg` (brand navy, for light backgrounds) and `logo-white.svg` (used on the
   dark cover/hero).
   The **hero background** (`hero-bg.svg`) and the demo
   `diagram-*.svg` / `chart.svg` are generic, license-clean placeholders --- swap
   them for your own.
   Filenames referenced by `index.qmd` / `styles.css`:
   `hero-bg.svg`, `logo-white.svg`, `diagram-light.svg`, `diagram-dark.svg`,
   `chart.svg`.
2. **This is an annotated showcase**, not a bare skeleton: each section renders an
   example *and* explains it, so the built document doubles as documentation.
   Delete the demo prose in the `_*.qmd` partials to turn it into a clean scaffold.
