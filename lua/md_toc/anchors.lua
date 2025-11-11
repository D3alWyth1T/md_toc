-- anchors.lua - Generate anchor links for different markdown flavors
local M = {}

-- Helper function to check if a character is alphanumeric
local function is_alnum(char)
  return char:match("[%w]") ~= nil
end

-- Helper function to check if character is in extended range (accents, CJK, Arabic, etc.)
local function is_extended(char)
  local byte = char:byte()
  if not byte then return false end

  -- Latin-1 Supplement and Latin Extended (U+00C0-U+00FF, U+0100-U+017F)
  if byte >= 0xC0 and byte <= 0xFF then return true end

  -- Cyrillic (U+0400-U+04FF) - handled by UTF-8 multi-byte
  -- Arabic (U+0600-U+06FF)
  -- CJK Unified Ideographs (U+4E00-U+9FBF)
  -- Hiragana (U+3040-U+309F)
  -- Katakana (U+30A0-U+30FF)
  -- Hangul (U+AC00-U+D7AF)

  -- For proper Unicode handling, check UTF-8 multi-byte sequences
  local str_byte = string.byte(char, 1)
  if str_byte > 127 then
    return true -- Assume extended Unicode character
  end

  return false
end

-- GFM (GitHub Flavored Markdown) anchor generation
-- Rules:
-- 1. Convert to lowercase
-- 2. Remove special chars (keep alphanumeric, spaces, hyphens, underscores, and extended Unicode)
-- 3. Replace spaces with hyphens
-- 4. Handle duplicates by appending -1, -2, etc.
function M.generate_gfm(heading_text, existing_anchors)
  existing_anchors = existing_anchors or {}

  -- Convert to lowercase
  local anchor = heading_text:lower()

  -- Remove special characters, keeping alphanumeric, spaces, hyphens, underscores, and extended chars
  local cleaned = {}
  -- Use UTF-8 pattern to iterate over characters
  for _, char in utf8.codes(anchor) do
    local c = utf8.char(char)
    if is_alnum(c) or is_extended(c) or c == " " or c == "-" or c == "_" then
      table.insert(cleaned, c)
    end
  end
  anchor = table.concat(cleaned, "")

  -- Replace spaces with hyphens
  anchor = anchor:gsub(" ", "-")

  -- Handle duplicates
  local base_anchor = anchor
  local counter = 1
  while existing_anchors[anchor] do
    anchor = base_anchor .. "-" .. counter
    counter = counter + 1
  end

  existing_anchors[anchor] = true
  return anchor
end

-- GitLab anchor generation
-- Similar to GFM but with different handling:
-- 1. Lowercase
-- 2. Remove special chars
-- 3. Replace spaces with hyphens
-- 4. Strip leading/trailing hyphens and underscores
-- 5. Consolidate multiple hyphens
function M.generate_gitlab(heading_text, existing_anchors)
  existing_anchors = existing_anchors or {}

  -- Convert to lowercase
  local anchor = heading_text:lower()

  -- Remove special characters
  local cleaned = {}
  -- Use UTF-8 pattern to iterate over characters
  for _, char in utf8.codes(anchor) do
    local c = utf8.char(char)
    if is_alnum(c) or is_extended(c) or c == " " or c == "-" or c == "_" then
      table.insert(cleaned, c)
    end
  end
  anchor = table.concat(cleaned, "")

  -- Replace spaces with hyphens
  anchor = anchor:gsub(" ", "-")

  -- Consolidate multiple hyphens
  anchor = anchor:gsub("-+", "-")

  -- Strip leading and trailing hyphens and underscores
  anchor = anchor:gsub("^[-_]+", "")
  anchor = anchor:gsub("[-_]+$", "")

  -- Handle duplicates
  local base_anchor = anchor
  local counter = 1
  while existing_anchors[anchor] do
    anchor = base_anchor .. "-" .. counter
    counter = counter + 1
  end

  existing_anchors[anchor] = true
  return anchor
end

-- Redcarpet anchor generation
-- Rules:
-- 1. Lowercase
-- 2. Replace some chars with HTML entities (&, ", ', <, >)
-- 3. Remove/consolidate special chars
-- 4. Consolidate to single hyphen
function M.generate_redcarpet(heading_text, existing_anchors)
  existing_anchors = existing_anchors or {}

  -- Convert to lowercase
  local anchor = heading_text:lower()

  -- HTML entity replacements
  anchor = anchor:gsub("&", "&amp;")
  anchor = anchor:gsub('"', "&quot;")
  anchor = anchor:gsub("'", "&#39;")
  anchor = anchor:gsub("<", "&lt;")
  anchor = anchor:gsub(">", "&gt;")

  -- Replace non-alphanumeric with hyphens (except extended chars)
  local cleaned = {}
  -- Use UTF-8 pattern to iterate over characters
  for _, char in utf8.codes(anchor) do
    local c = utf8.char(char)
    if is_alnum(c) or is_extended(c) then
      table.insert(cleaned, c)
    elseif c == " " or c:match("[^%w]") then
      table.insert(cleaned, "-")
    else
      table.insert(cleaned, c)
    end
  end
  anchor = table.concat(cleaned, "")

  -- Consolidate multiple hyphens
  anchor = anchor:gsub("-+", "-")

  -- Strip leading and trailing hyphens
  anchor = anchor:gsub("^-+", "")
  anchor = anchor:gsub("-+$", "")

  -- Handle duplicates
  local base_anchor = anchor
  local counter = 1
  while existing_anchors[anchor] do
    anchor = base_anchor .. "-" .. counter
    counter = counter + 1
  end

  existing_anchors[anchor] = true
  return anchor
end

-- Marked anchor generation
-- Rules:
-- 1. Lowercase
-- 2. Replace spaces with hyphens
-- 3. Minimal character transformation
function M.generate_marked(heading_text, existing_anchors)
  existing_anchors = existing_anchors or {}

  -- Convert to lowercase
  local anchor = heading_text:lower()

  -- Replace spaces with hyphens and remove most special chars
  local cleaned = {}
  -- Use UTF-8 pattern to iterate over characters
  for _, char in utf8.codes(anchor) do
    local c = utf8.char(char)
    if is_alnum(c) or is_extended(c) or c == "-" then
      table.insert(cleaned, c)
    elseif c == " " then
      table.insert(cleaned, "-")
    end
  end
  anchor = table.concat(cleaned, "")

  -- Handle duplicates
  local base_anchor = anchor
  local counter = 1
  while existing_anchors[anchor] do
    anchor = base_anchor .. "-" .. counter
    counter = counter + 1
  end

  existing_anchors[anchor] = true
  return anchor
end

-- Main function to generate anchor based on style
function M.generate(heading_text, style, existing_anchors)
  style = style or "gfm"

  if style == "gfm" then
    return M.generate_gfm(heading_text, existing_anchors)
  elseif style == "gitlab" then
    return M.generate_gitlab(heading_text, existing_anchors)
  elseif style == "redcarpet" then
    return M.generate_redcarpet(heading_text, existing_anchors)
  elseif style == "marked" then
    return M.generate_marked(heading_text, existing_anchors)
  else
    vim.notify("Unknown anchor style: " .. style .. ", using GFM", vim.log.levels.WARN)
    return M.generate_gfm(heading_text, existing_anchors)
  end
end

return M
