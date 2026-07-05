// layout.typ — document-level Typst setup for the PDF, injected via
// `include-before-body`. Runs AFTER Quarto injects its code-highlight theme,
// so overrides here win.

// ---- Page margins -----------------------------------------------------------
// Quarto hands page geometry to the `marginalia` package (it powers margin
// notes / `.column-margin` — see _native.qmd). Its default reserves a HUGE
// outer note column (~1.6in) + wide `far` margins, so ~40% of A4 is margin and
// the `margin:` YAML key barely affects it. Re-run setup here (this file is
// injected AFTER Quarto's setup, so it wins) with tighter geometry: a slim left
// margin, no inner notes, and a functional-but-narrow right note column.
// To go FULL-WIDTH (no margin notes): set outer.width to 0cm and stop using
// `.column-margin` / margin footnotes, or route footnotes to the page bottom.
#import "@preview/marginalia:0.3.1" as marginalia
#show: marginalia.setup.with(
  inner: (far: 3cm, width: 0cm,  sep: 0cm),    // margin-note column
  outer: (far: 3cm, width: 0cm,  sep: 0cm),  // margin-note column
  top: 2cm,
  bottom: 2cm,
)

#set par(justify: false)
#set text(size: 10pt)

// Code blocks: monospace, boxed, rounded.
#show raw: set text(font: ("Roboto Mono"), size: 8pt)
#show raw.where(block: true): set block(fill: luma(245), inset: 10pt, radius: 4pt)

// Figure spacing.
#show figure: set block(spacing: 3em)          // space around the whole figure
#show figure.caption: set pad(top: 0.8em)       // gap between image and caption

// Math: nudge sizes so equations read clearly next to Roboto's x-height.
#show math.equation.where(block: false): set text(size: 1.05em)
#show math.equation.where(block: true): set text(size: 1.2em)
