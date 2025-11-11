-- toc.lua - Core TOC generation, update, and removal
local anchors = require("md_toc.anchors")
local headings = require("md_toc.headings")
local utils = require("md_toc.utils")

local M = {}

-- Generate TOC lines from headings
local function generate_toc_lines(heading_list, style, config)
  local toc_lines = {}
  local existing_anchors = {}
  local indent_text = utils.get_indent_text(config)

  -- Find minimum level for relative indentation
  local min_level = math.huge
  for _, heading in ipairs(heading_list) do
    if heading.level < min_level then
      min_level = heading.level
    end
  end

  for _, heading in ipairs(heading_list) do
    -- Generate anchor link
    local anchor = anchors.generate(heading.text, style, existing_anchors)

    -- Calculate indentation (relative to minimum level)
    local indent_level = heading.level - min_level
    local indent = string.rep(indent_text, indent_level)

    -- Get list marker
    local list_marker = utils.get_list_marker(heading.level, config)

    -- Generate TOC line: "    * [Heading Text](#anchor-link)"
    local toc_line = string.format("%s%s [%s](#%s)", indent, list_marker, heading.text, anchor)
    table.insert(toc_lines, toc_line)
  end

  return toc_lines
end

-- Generate TOC at cursor position
function M.generate(bufnr, config)
  bufnr = bufnr or 0

  -- Check if buffer is markdown
  if not utils.is_markdown_buffer(bufnr) then
    vim.notify("Not a markdown buffer", vim.log.levels.ERROR)
    return false
  end

  -- Extract headings
  local heading_list = headings.extract_headings(bufnr, config)

  if #heading_list == 0 then
    vim.notify("No headings found in buffer", vim.log.levels.WARN)
    return false
  end

  -- Check if TOC already exists
  local existing_start, existing_end = utils.find_toc_fence(bufnr, config)
  if existing_start and existing_end then
    vim.notify("TOC already exists. Use :MdTocUpdate to update it.", vim.log.levels.WARN)
    return false
  end

  -- Get current style
  local style = config.style or "gfm"

  -- Generate TOC lines
  local toc_lines = generate_toc_lines(heading_list, style, config)

  -- Generate fence markers
  local opening_fence, closing_fence = utils.generate_fence_markers(style, config)

  -- Build complete TOC with fences
  local complete_toc = {}
  if not config.dont_insert_fence then
    table.insert(complete_toc, opening_fence)
    table.insert(complete_toc, "")
  end

  for _, line in ipairs(toc_lines) do
    table.insert(complete_toc, line)
  end

  if not config.dont_insert_fence then
    table.insert(complete_toc, "")
    table.insert(complete_toc, closing_fence)
  end

  -- Insert TOC at cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local insert_line = cursor[1]

  utils.insert_lines(bufnr, insert_line, complete_toc)

  vim.notify("TOC generated successfully", vim.log.levels.INFO)
  return true
end

-- Update existing TOC
function M.update(bufnr, config)
  bufnr = bufnr or 0

  -- Check if buffer is markdown
  if not utils.is_markdown_buffer(bufnr) then
    vim.notify("Not a markdown buffer", vim.log.levels.ERROR)
    return false
  end

  -- Find existing TOC
  local toc_start, toc_end = utils.find_toc_fence(bufnr, config)
  if not toc_start or not toc_end then
    vim.notify("No TOC found. Use :MdTocGenerate to create one.", vim.log.levels.WARN)
    return false
  end

  -- Get style from existing fence
  local opening_line = utils.get_lines(bufnr, toc_start, toc_start)[1]
  local style = utils.get_style_from_fence(opening_line, config)

  -- Extract headings (excluding the TOC itself)
  local heading_list = headings.extract_headings(bufnr, config)

  -- Filter out headings within the TOC
  local filtered_headings = {}
  for _, heading in ipairs(heading_list) do
    if heading.line_num < toc_start or heading.line_num > toc_end then
      table.insert(filtered_headings, heading)
    end
  end

  if #filtered_headings == 0 then
    vim.notify("No headings found in buffer", vim.log.levels.WARN)
    return false
  end

  -- Generate new TOC lines
  local toc_lines = generate_toc_lines(filtered_headings, style, config)

  -- Generate fence markers
  local opening_fence, closing_fence = utils.generate_fence_markers(style, config)

  -- Build complete TOC
  local complete_toc = {}
  if not config.dont_insert_fence then
    table.insert(complete_toc, opening_fence)
    table.insert(complete_toc, "")
  end

  for _, line in ipairs(toc_lines) do
    table.insert(complete_toc, line)
  end

  if not config.dont_insert_fence then
    table.insert(complete_toc, "")
    table.insert(complete_toc, closing_fence)
  end

  -- Replace old TOC with new one
  utils.set_lines(bufnr, toc_start, toc_end, complete_toc)

  vim.notify("TOC updated successfully", vim.log.levels.INFO)
  return true
end

-- Remove TOC from buffer
function M.remove(bufnr, config)
  bufnr = bufnr or 0

  -- Check if buffer is markdown
  if not utils.is_markdown_buffer(bufnr) then
    vim.notify("Not a markdown buffer", vim.log.levels.ERROR)
    return false
  end

  -- Find existing TOC
  local toc_start, toc_end = utils.find_toc_fence(bufnr, config)
  if not toc_start or not toc_end then
    vim.notify("No TOC found to remove", vim.log.levels.WARN)
    return false
  end

  -- Delete TOC lines
  utils.delete_lines(bufnr, toc_start, toc_end)

  vim.notify("TOC removed successfully", vim.log.levels.INFO)
  return true
end

-- Jump to heading under cursor (if cursor is on a TOC entry)
function M.goto_heading(bufnr)
  bufnr = bufnr or 0

  -- Get current line
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

  if not line then
    return false
  end

  -- Extract anchor from TOC line: * [Text](#anchor)
  local anchor = line:match("%[.-%]%(#([^%)]+)%)")
  if not anchor then
    vim.notify("No TOC link found on current line", vim.log.levels.WARN)
    return false
  end

  -- Find the TOC to know where to skip
  local config = require("md_toc.config").get()
  local toc_start, toc_end = utils.find_toc_fence(bufnr, config)

  -- Search for heading with matching anchor
  local all_headings = headings.extract_headings(bufnr, config)
  local existing_anchors = {}

  for _, heading in ipairs(all_headings) do
    -- Skip headings within TOC
    if not (toc_start and toc_end and heading.line_num >= toc_start and heading.line_num <= toc_end) then
      local heading_anchor = anchors.generate(heading.text, config.style, existing_anchors)

      if heading_anchor == anchor then
        utils.goto_line(heading.line_num)
        vim.notify(string.format("Jumped to: %s", heading.text), vim.log.levels.INFO)
        return true
      end
    end
  end

  vim.notify("Could not find heading for anchor: " .. anchor, vim.log.levels.WARN)
  return false
end

return M
