-- utils.lua - Utility functions for md_toc
local M = {}

-- Get indent text based on config
function M.get_indent_text(config)
  local indent_size = config.indent_size or 4
  return string.rep(" ", indent_size)
end

-- Generate list marker (with optional cycling)
function M.get_list_marker(level, config)
  local marker = config.list_marker or "*"

  if config.cycle_list_markers then
    local markers = { "*", "-", "+" }
    local idx = ((level - 1) % 3) + 1
    return markers[idx]
  end

  return marker
end

-- Find TOC fence in buffer
-- Returns: start_line, end_line (1-indexed) or nil, nil if not found
function M.find_toc_fence(bufnr, config)
  bufnr = bufnr or 0
  local fence_text = config.fence_text or "md_toc"
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local start_line = nil
  local end_line = nil

  for i, line in ipairs(lines) do
    -- Look for opening fence: <!-- md_toc STYLE -->
    if not start_line and line:match("<!%-%-[%s]*" .. fence_text .. "[%s]+%w+[%s]*%-%->") then
      start_line = i
    -- Look for closing fence: <!-- md_toc -->
    elseif start_line and line:match("<!%-%-[%s]*" .. fence_text .. "[%s]*%-%->") then
      end_line = i
      break
    end
  end

  if start_line and end_line then
    return start_line, end_line
  end

  return nil, nil
end

-- Get style from opening fence
function M.get_style_from_fence(line, config)
  local fence_text = config.fence_text or "md_toc"
  local style = line:match("<!%-%-[%s]*" .. fence_text .. "[%s]+(%w+)[%s]*%-%->")
  if style then
    return style:lower()
  end
  return config.style or "gfm"
end

-- Generate fence markers
function M.generate_fence_markers(style, config)
  local fence_text = config.fence_text or "md_toc"
  local opening = string.format("<!-- %s %s -->", fence_text, style:upper())
  local closing = string.format("<!-- %s -->", fence_text)
  return opening, closing
end

-- Check if buffer is a markdown file
function M.is_markdown_buffer(bufnr)
  bufnr = bufnr or 0
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local filename = vim.api.nvim_buf_get_name(bufnr)

  -- Check filetype or file extension
  return filetype == "markdown"
    or filetype == "md"
    or filetype == "telekasten"
    or filename:match("%.md$")
    or filename:match("%.markdown$")
end

-- Get buffer lines in a range (1-indexed, inclusive)
function M.get_lines(bufnr, start_line, end_line)
  bufnr = bufnr or 0
  -- Convert to 0-indexed for API
  return vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
end

-- Set buffer lines in a range (1-indexed, inclusive)
function M.set_lines(bufnr, start_line, end_line, lines)
  bufnr = bufnr or 0
  -- Convert to 0-indexed for API
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
end

-- Delete lines in a range (1-indexed, inclusive)
function M.delete_lines(bufnr, start_line, end_line)
  bufnr = bufnr or 0
  -- Convert to 0-indexed for API
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, {})
end

-- Insert lines at position (1-indexed)
function M.insert_lines(bufnr, line_num, lines)
  bufnr = bufnr or 0
  -- Convert to 0-indexed for API
  vim.api.nvim_buf_set_lines(bufnr, line_num - 1, line_num - 1, false, lines)
end

-- Move cursor to line
function M.goto_line(line_num)
  vim.api.nvim_win_set_cursor(0, { line_num, 0 })
end

-- Check if Telekasten is loaded
function M.is_telekasten_loaded()
  return pcall(require, "telekasten")
end

-- Check if Telescope is loaded
function M.is_telescope_loaded()
  return pcall(require, "telescope")
end

return M
