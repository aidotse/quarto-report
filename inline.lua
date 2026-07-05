-- inline.lua — Pandoc filter that gives the PDF (Typst) and the HTML the same
-- custom components from a single Markdown source.
--
-- HOW IT WORKS:
--   * For HTML output we mostly leave the fenced divs/spans alone (their classes
--     are styled by styles.css) and only tweak inline code so it beats Bootstrap.
--   * For Typst output we REWRITE the div/span into a raw Typst function call
--     (e.g. `::: {.custom-card .positive-theme}` -> `#CustomCard("positive")[...]`).
--     Those functions are defined in style.typ.
--
-- To add a new component: add a branch here, a Typst function in style.typ, and a
-- CSS rule in styles.css using the same class name.

-- Intercept inline `code` spans
function Code(el)
  -- 1. PDF: bypass Pandoc's default and inject our own raw Typst wrapper
  if FORMAT == "typst" then
    return pandoc.RawInline('typst', '#InlineCode[`' .. el.text .. '`]')
  end

  -- 2. Web: inject a hard-coded class so we can beat Bootstrap's CSS
  if FORMAT == "html" then
    el.classes:insert('inline-code')
    return el
  end
end

-- Intercept Images tagged .img-rounded: give the PDF the same rounded corners +
-- hairline border that styles.css gives the HTML (Typst drops the class otherwise).
function Image(el)
  if FORMAT ~= "typst" then return nil end
  if not el.classes:includes("img-rounded") then return nil end

  local width = el.attributes["width"]
  local w = width and (', width: ' .. width) or ''
  return pandoc.RawInline('typst',
    '#box(clip: true, radius: 8pt, stroke: 0.75pt + luma(180))[#image("' ..
    el.src .. '"' .. w .. ')]')
end

-- Intercept Spans (inline text: badges, subtext, labels)
function Span(el)
  if FORMAT ~= "typst" then return nil end  -- HTML uses styles.css directly

  if el.classes:includes("orange-badge") then
    return pandoc.RawInline('typst', '#highlight(fill: rgb("#FFE0B2"))[#text(fill: rgb("#E65100"), weight: "bold")[' .. pandoc.utils.stringify(el) .. ']]')
  end
  if el.classes:includes("subtext") then
    return pandoc.RawInline('typst', '#text(fill: rgb("#777777"), size: 0.9em)[' .. pandoc.utils.stringify(el) .. ']')
  end
  if el.classes:includes("quiz-tag") then
    return pandoc.RawInline('typst', '#QuizTag[' .. pandoc.utils.stringify(el) .. ']')
  end
  if el.classes:includes("label-orange") then
    return pandoc.RawInline('typst', '#text(fill: rgb("#E65100"), font: "Roboto Mono", weight: "bold")[' .. pandoc.utils.stringify(el) .. ']')
  end
  if el.classes:includes("label-blue") then
    return pandoc.RawInline('typst', '#text(fill: rgb("#2196F3"), font: "Roboto Mono", weight: "bold")[' .. pandoc.utils.stringify(el) .. ']')
  end
  if el.classes:includes("label-dark") then
    return pandoc.RawInline('typst', '#text(fill: rgb("#333333"), font: "Roboto Mono", weight: "bold")[' .. pandoc.utils.stringify(el) .. ']')
  end
end

-- Intercept Divs (block-level cards and boxes)
function Div(el)
  if FORMAT ~= "typst" then return nil end  -- HTML uses styles.css directly

  -- Cards with a colored top border: .custom-card + .positive-theme / .negative-theme / .anchor-theme
  if el.classes:includes("custom-card") then
    local theme = "default"
    if el.classes:includes("anchor-theme")   then theme = "anchor"   end
    if el.classes:includes("positive-theme") then theme = "positive" end
    if el.classes:includes("negative-theme") then theme = "negative" end
    local inner = pandoc.write(pandoc.Pandoc(el.content), 'typst')
    return pandoc.RawBlock('typst', '#CustomCard("' .. theme .. '")[\n' .. inner .. '\n]')
  end

  if el.classes:includes("quiz-card") then
    local inner = pandoc.write(pandoc.Pandoc(el.content), 'typst')
    return pandoc.RawBlock('typst', '#QuizCard[\n' .. inner .. '\n]')
  end

  if el.classes:includes("mcq-option") then
    local is_correct = el.classes:includes("correct") and "true" or "false"
    local inner = pandoc.write(pandoc.Pandoc(el.content), 'typst')
    return pandoc.RawBlock('typst', '#McqOption(correct: ' .. is_correct .. ')[\n' .. inner .. '\n]')
  end

  if el.classes:includes("prompt-box") then
    local inner = pandoc.write(pandoc.Pandoc(el.content), 'typst')
    return pandoc.RawBlock('typst', '#PromptBox[\n' .. inner .. '\n]')
  end

  if el.classes:includes("algorithm-box") then
    local inner = pandoc.write(pandoc.Pandoc(el.content), 'typst')
    return pandoc.RawBlock('typst', '#algorithm-box[\n' .. inner .. '\n]')
  end

  if el.classes:includes("research-question-box") then
    local inner = pandoc.write(pandoc.Pandoc(el.content), 'typst')
    return pandoc.RawBlock('typst', '#researchbox[\n' .. inner .. '\n]')
  end
end
