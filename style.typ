// style.typ — Typst styling + custom component functions for the PDF output.
// Injected via `include-in-header` (see index.qmd). The functions here are the
// PDF-side counterparts of the CSS classes in styles.css; inline.lua rewrites
// the Markdown divs/spans into calls to these functions.

// ---- Base type ------------------------------------------------------------
// Sleek sans-serif base font, falling back to Arial. (Inter is also bundled in
// assets/fonts if you prefer it — see the commented line.)
//#set text(font: ("Inter 18pt", "Segoe UI", "Arial"), fill: rgb("#333333"), tracking: -0.030em, spacing: 120%)
#set text(font: ("Roboto", "Arial"), fill: rgb("#333333"), tracking: -0.020em, spacing: 130%)
#set par(leading: 0.8em)

// ---- Heading system -------------------------------------------------------
// NOTE: levels are POSITIONAL — they follow the order headings first appear.
// If you skip `#` and open with `##`, that `##` is treated as level 1.
#show heading: it => {
  if it.level == 1 {
    // Start every top-level (`#`) section on a fresh page. `weak: true` avoids a
    // blank page when we're already at the top (e.g. the first section after the cover).
    pagebreak(weak: true)
    v(1.2em); text(size: 14pt, weight: "bold", fill: rgb("#666666"), it); v(0.5em)
  } else if it.level == 2 {
    v(1em); text(size: 12pt, weight: "bold", fill: rgb("#777777"), it); v(0.5em)
  } else if it.level == 3 {
    v(1em); text(size: 10pt, weight: "bold", fill: rgb("#888888"), it); v(0.5em)
  } else {
    v(0.75em); text(size: 10pt, weight: "bold", fill: rgb("#999999"), it); v(0.3em)
  }
}

// ---- Links & citations ----------------------------------------------------
#show link: it => underline(text(fill: rgb("#0055CC"), it))
#show cite: it => text(fill: rgb("#0055CC"), it)

// Suppress Typst's built-in "Bibliography" title. Quarto appends a
// `#bibliography(...)` call for the PDF, which otherwise emits its own heading —
// giving us a duplicate ("References" from index.qmd + "Bibliography" here).
// With the title off, the entries render directly under our `# References`.
#set bibliography(title: none)

// ---- Research-question / outlined box -------------------------------------
#let researchbox(body) = block(
  width: 100%,
  stroke: 1pt + black,
  inset: 15pt,
  body,
)

// ---- Inline code (triggered by inline.lua's #InlineCode) ------------------
#let InlineCode(body) = {
  show raw: set text(fill: rgb("#333333"))  // override Typst raw defaults
  box(
    fill: rgb("#f2f2f2"),
    inset: (x: 3pt, y: 0pt),
    outset: (y: 3pt),
    radius: 2pt,
    body,
  )
}

// ---- Data cards (colored top border keyed by theme) -----------------------
#let CustomCard(theme, body) = {
  let top-color = rgb("#E0E0E0")
  if theme == "anchor"   { top-color = rgb("#2196F3") }
  if theme == "positive" { top-color = rgb("#4CAF50") }
  if theme == "negative" { top-color = rgb("#E63946") }
  block(
    fill: rgb("#FAFAFA"),
    stroke: (top: 4pt + top-color, rest: 1pt + rgb("#E0E0E0")),
    inset: 12pt,
    radius: 4pt,
    width: 100%,
    body,
  )
}

// ---- Quiz card + pill tags + multiple-choice options ----------------------
#let QuizCard(body) = block(
  fill: rgb("#FCFCFC"),
  stroke: 1pt + rgb("#E0E0E0"),
  inset: 15pt,
  radius: 8pt,
  width: 100%,
)[
  #set block(spacing: 0.8em)
  #set par(spacing: 0.8em)
  #body
]

#let QuizTag(body) = {
  box(
    fill: rgb("#EEEEEE"),
    inset: (x: 8pt, y: 4pt),
    radius: 12pt,
    text(font: ("Roboto Mono", "Consolas"), size: 0.7em, fill: rgb("#555555"), body),
  )
  h(4pt)
}

#let McqOption(correct: false, body) = block(
  fill: if correct { rgb("#E8F5E9") } else { rgb("#FAFAFA") },
  stroke: if correct { 2pt + rgb("#4CAF50") } else { 1pt + rgb("#E0E0E0") },
  inset: 10pt,
  radius: 6pt,
  width: 100%,
  text(fill: if correct { rgb("#2E7D32") } else { rgb("#333333") }, body),
)

// ---- System-prompt box (left accent bar) ----------------------------------
#let PromptBox(body) = block(
  breakable: false,
  above: 2.0em,
  below: 2.0em,
  fill: rgb("#F8F9FA"),
  stroke: (left: 4pt + rgb("#673AB7"), rest: 1pt + rgb("#E0E0E0")),
  inset: 15pt,
  radius: (left: 2pt, right: 6pt),
  width: 100%,
)[
  #set text(size: 0.95em)
  #body
]

// ---- Algorithm box --------------------------------------------------------
#let algorithm-box(body) = block(
  fill: luma(245),
  stroke: 1pt + rgb(224, 224, 224),
  inset: 15pt,
  above: 1.5em,
  below: 1.5em,
  radius: 4pt,
  width: 100%,
  breakable: false,
  body,
)

// ---- Table behavior -------------------------------------------------------
// Keep tables from splitting across pages.
#show figure.where(kind: table): set block(breakable: false)
#show table: it => block(breakable: false, it)
