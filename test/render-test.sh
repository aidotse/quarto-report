#!/usr/bin/env bash
# =============================================================================
# render-test.sh — smoke test for the dual-format Quarto template.
#
# Renders the report to HTML and PDF and asserts the invariants that matter for
# THIS template — most importantly that the custom components survive into BOTH
# outputs. A plain `quarto render` only tells you the build didn't crash; it will
# happily produce a PDF that silently dropped a component if the inline.lua ->
# style.typ mapping breaks. This test guards that seam.
#
# Usage:
#   bash test/render-test.sh          # render, assert, then clean up artifacts
#   bash test/render-test.sh --keep   # leave _site/ and index.typ in place
#
# Exit code 0 = all checks passed, 1 = one or more failed (CI-friendly).
#
# Maintenance: when you add a new component, add its HTML class to
# CUSTOM_CLASSES and its Typst call to TYPST_CALLS below.
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

KEEP=0
[[ "${1:-}" == "--keep" ]] && KEEP=1

PASS=0
FAIL=0
red()   { printf '\033[31m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }

pass() { PASS=$((PASS+1)); printf '  %s %s\n' "$(green PASS)" "$1"; }
fail() { FAIL=$((FAIL+1)); printf '  %s %s\n' "$(red FAIL)" "$1"; }

# assert a file exists and is non-empty
assert_file() {
  if [[ -s "$1" ]]; then pass "file exists & non-empty: $1"; else fail "missing/empty: $1"; fi
}
# assert FILE contains literal PATTERN
assert_has() {
  local file="$1" pat="$2" desc="${3:-contains '$2'}"
  if grep -qF -- "$pat" "$file" 2>/dev/null; then pass "$desc"; else fail "$desc  (missing '$pat' in $file)"; fi
}
# assert FILE does NOT contain literal PATTERN
assert_absent() {
  local file="$1" pat="$2" desc="${3:-no '$2'}"
  if grep -qF -- "$pat" "$file" 2>/dev/null; then fail "$desc  (unexpected '$pat' in $file)"; else pass "$desc"; fi
}

cleanup() { [[ $KEEP -eq 0 ]] && rm -rf _site index_files .quarto index.typ; }
trap cleanup EXIT

command -v quarto >/dev/null || { echo "ERROR: quarto not found on PATH"; exit 1; }
echo "Using $(quarto --version) at $ROOT"

# -----------------------------------------------------------------------------
echo ""; echo "== Rendering HTML =="
if quarto render index.qmd --to html --quiet; then pass "quarto render (html) exited 0"; else fail "quarto render (html) failed"; fi

echo ""; echo "== Rendering PDF (keep intermediate .typ) =="
if quarto render index.qmd --to typst -M keep-typ:true --quiet; then pass "quarto render (typst) exited 0"; else fail "quarto render (typst) failed"; fi

HTML="_site/index.html"
PDF="_site/index.pdf"

echo ""; echo "== Output artifacts =="
assert_file "$HTML"
assert_file "$PDF"
assert_file "index.typ"
if file "$PDF" 2>/dev/null | grep -q "PDF document"; then pass "index.pdf is a valid PDF"; else fail "index.pdf is not a valid PDF"; fi
PAGES=$(file "$PDF" 2>/dev/null | grep -oE '[0-9]+ page' | grep -oE '[0-9]+' || echo 0)
if [[ "${PAGES:-0}" -ge 5 ]]; then pass "PDF has a sane page count ($PAGES)"; else fail "PDF page count too low ($PAGES)"; fi

# -----------------------------------------------------------------------------
# Every custom class (from inline.lua + styles.css) must appear in the HTML.
# If a component silently stops rendering, this list catches it.
echo ""; echo "== Custom components in HTML =="
CUSTOM_CLASSES=(
  inline-code orange-badge subtext quiz-tag
  label-orange label-blue label-dark
  custom-card anchor-theme positive-theme negative-theme
  quiz-card "mcq-option correct" prompt-box algorithm-box research-question-box
  list-indent img-rounded auto-invert light-island
  datawrapper-panel-group hero-banner author-box divider-line
)
for c in "${CUSTOM_CLASSES[@]}"; do assert_has "$HTML" "$c" "HTML has .$c"; done

echo ""; echo "== Native Quarto constructs in HTML =="
for c in callout-note callout-tip callout-warning callout-important callout-caution panel-tabset column-margin; do
  assert_has "$HTML" "$c" "HTML has .$c"
done

# -----------------------------------------------------------------------------
# The PDF path is the fragile one: verify the Typst function calls that inline.lua
# is supposed to emit actually made it into the generated Typst.
echo ""; echo "== Custom components reached the PDF (Typst) =="
TYPST_CALLS=( "#InlineCode" "#CustomCard(" "#QuizCard" "#McqOption(" "#PromptBox" "#algorithm-box" "#researchbox" "#QuizTag" "clip: true, radius: 8pt" )
for t in "${TYPST_CALLS[@]}"; do assert_has "index.typ" "$t" "Typst emits $t"; done
assert_has "index.typ" "callout" "Typst emits callouts"

# -----------------------------------------------------------------------------
echo ""; echo "== References & cross-references resolved =="
assert_absent "$HTML" "?@"    "no unresolved citations (?@)"
assert_absent "$HTML" "?fig-" "no unresolved figure refs (?fig-)"
assert_absent "$HTML" "?tbl-" "no unresolved table refs (?tbl-)"
assert_has    "$HTML" "ref-example2025" "bibliography populated (ref-example2025)"

# -----------------------------------------------------------------------------
echo ""
echo "----------------------------------------"
printf 'Result: %s passed, %s failed\n' "$(green "$PASS")" "$([[ $FAIL -gt 0 ]] && red "$FAIL" || echo 0)"
[[ $FAIL -eq 0 ]]
