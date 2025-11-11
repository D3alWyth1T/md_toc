-- headings.lua - Extract and parse markdown headings
local M = {}

-- Check if a line is within a code block
local function is_in_code_block(line_num, code_blocks)
  for _, block in ipairs(code_blocks) do
    if line_num >= block.start_line and line_num <= block.end_line then
      return true
    end
  end
  return false
end

-- Find all code blocks and YAML frontmatter in the buffer
local function find_code_blocks(lines)
  local code_blocks = {}
  local in_block = false
  local block_start = nil
  local fence_pattern = nil

  for i, line in ipairs(lines) do
    -- Check for YAML frontmatter (--- at start of file)
    if i == 1 and line:match("^%-%-%-+%s*$") then
      in_block = true
      block_start = i
      fence_pattern = "yaml"
    -- Check for code fence start (``` or ~~~)
    elseif not in_block then
      if line:match("^```") then
        in_block = true
        block_start = i
        fence_pattern = "```"
      elseif line:match("^~~~") then
        in_block = true
        block_start = i
        fence_pattern = "~~~"
      elseif line:match("^{%% highlight") then
        in_block = true
        block_start = i
        fence_pattern = "endhighlight"
      end
    else
      -- Check for code fence end
      if fence_pattern == "yaml" and line:match("^%-%-%-+%s*$") then
        table.insert(code_blocks, { start_line = block_start, end_line = i })
        in_block = false
        block_start = nil
        fence_pattern = nil
      elseif fence_pattern == "```" and line:match("^```") then
        table.insert(code_blocks, { start_line = block_start, end_line = i })
        in_block = false
        block_start = nil
        fence_pattern = nil
      elseif fence_pattern == "~~~" and line:match("^~~~") then
        table.insert(code_blocks, { start_line = block_start, end_line = i })
        in_block = false
        block_start = nil
        fence_pattern = nil
      elseif fence_pattern == "endhighlight" and line:match("{%% endhighlight %%}") then
        table.insert(code_blocks, { start_line = block_start, end_line = i })
        in_block = false
        block_start = nil
        fence_pattern = nil
      end
    end
  end

  -- If still in block at end, close it
  if in_block and block_start then
    table.insert(code_blocks, { start_line = block_start, end_line = #lines })
  end

  return code_blocks
end

-- Parse ATX-style headings (# Heading)
local function parse_atx_heading(line)
  local hashes, text = line:match("^(#{1,6})%s+(.+)$")
  if hashes and text then
    -- Remove trailing hashes if present
    text = text:gsub("%s*#+%s*$", "")
    return #hashes, text
  end
  return nil, nil
end

-- Parse Setext-style headings (Heading followed by === or ---)
local function parse_setext_heading(current_line, next_line)
  if not current_line or not next_line then
    return nil, nil
  end

  -- Check if next line is all = or all -
  if next_line:match("^=+%s*$") then
    -- Level 1 heading
    return 1, current_line:match("^%s*(.-)%s*$") -- trim whitespace
  elseif next_line:match("^-+%s*$") then
    -- Level 2 heading
    return 2, current_line:match("^%s*(.-)%s*$") -- trim whitespace
  end

  return nil, nil
end

-- Extract all headings from buffer
function M.extract_headings(bufnr, config)
  bufnr = bufnr or 0
  config = config or {}

  local min_level = config.min_level or 1
  local max_level = config.max_level or 6

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local code_blocks = find_code_blocks(lines)

  -- Debug: print code blocks
  if vim.g.md_toc_debug then
    print("Code blocks found:")
    for _, block in ipairs(code_blocks) do
      print(string.format("  Lines %d-%d", block.start_line, block.end_line))
    end
  end

  local headings = {}

  local i = 1
  while i <= #lines do
    local line = lines[i]

    -- Skip if in code block
    if not is_in_code_block(i, code_blocks) then
      -- Try ATX-style heading
      local level, text = parse_atx_heading(line)

      if vim.g.md_toc_debug and line:match("^##") then
        print(string.format("Line %d: '%s' -> level=%s, text='%s'", i, line, tostring(level), tostring(text)))
      end

      -- If not ATX, try Setext-style
      if not level and i < #lines then
        level, text = parse_setext_heading(line, lines[i + 1])
        if level then
          -- Skip the underline for Setext
          i = i + 1
        end
      end

      -- If we found a heading and it's within the level range
      if level and text and level >= min_level and level <= max_level then
        table.insert(headings, {
          level = level,
          text = text,
          line_num = i,
        })
      end
    end

    i = i + 1
  end

  if vim.g.md_toc_debug then
    print(string.format("Total headings found: %d", #headings))
  end

  return headings
end

-- Get the heading under the cursor
function M.get_heading_at_cursor(bufnr)
  bufnr = bufnr or 0
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]

  if not line then
    return nil
  end

  -- Check if current line is a heading
  local level, text = parse_atx_heading(line)
  if level and text then
    return { level = level, text = text, line_num = line_num }
  end

  -- Check if next line makes current line a Setext heading
  if line_num < vim.api.nvim_buf_line_count(bufnr) then
    local next_line = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)[1]
    level, text = parse_setext_heading(line, next_line)
    if level and text then
      return { level = level, text = text, line_num = line_num }
    end
  end

  return nil
end

return M
