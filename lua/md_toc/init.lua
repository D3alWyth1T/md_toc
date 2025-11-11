-- init.lua - Main module for md_toc
local config = require("md_toc.config")
local toc = require("md_toc.toc")
local headings = require("md_toc.headings")
local anchors = require("md_toc.anchors")
local utils = require("md_toc.utils")

local M = {}

-- Plugin version
M.version = "1.0.0"

-- Setup function
function M.setup(user_config)
  -- Setup configuration
  local cfg = config.setup(user_config)

  -- Setup auto-update on save if enabled
  if cfg.auto_update then
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.md", "*.markdown" },
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        if utils.is_markdown_buffer(bufnr) then
          local toc_start, toc_end = utils.find_toc_fence(bufnr, cfg)
          if toc_start and toc_end then
            -- Silently update TOC
            toc.update(bufnr, cfg)
          end
        end
      end,
    })
  end

  -- Setup Telekasten integration if enabled and available
  if cfg.telekasten_integration and utils.is_telekasten_loaded() then
    M.setup_telekasten_integration()
  end

  return M
end

-- Generate TOC
function M.generate()
  local bufnr = vim.api.nvim_get_current_buf()
  local cfg = config.get()
  return toc.generate(bufnr, cfg)
end

-- Update TOC
function M.update()
  local bufnr = vim.api.nvim_get_current_buf()
  local cfg = config.get()
  return toc.update(bufnr, cfg)
end

-- Remove TOC
function M.remove()
  local bufnr = vim.api.nvim_get_current_buf()
  local cfg = config.get()
  return toc.remove(bufnr, cfg)
end

-- Jump to heading under cursor
function M.goto()
  local bufnr = vim.api.nvim_get_current_buf()
  return toc.goto_heading(bufnr)
end

-- Navigate TOC with Telescope (if available)
function M.navigate()
  local bufnr = vim.api.nvim_get_current_buf()
  local cfg = config.get()

  -- Check if Telescope is available
  if not cfg.telescope_navigation or not utils.is_telescope_loaded() then
    vim.notify("Telescope not available, use :MdTocGoto instead", vim.log.levels.WARN)
    return false
  end

  local ok, pickers = pcall(require, "telescope.pickers")
  local ok2, finders = pcall(require, "telescope.finders")
  local ok3, conf = pcall(require, "telescope.config")
  local ok4, actions = pcall(require, "telescope.actions")
  local ok5, action_state = pcall(require, "telescope.actions.state")

  if not (ok and ok2 and ok3 and ok4 and ok5) then
    vim.notify("Failed to load Telescope modules", vim.log.levels.ERROR)
    return false
  end

  -- Extract headings
  local heading_list = headings.extract_headings(bufnr, cfg)

  if #heading_list == 0 then
    vim.notify("No headings found in buffer", vim.log.levels.WARN)
    return false
  end

  -- Generate entries for picker
  local entries = {}
  for _, heading in ipairs(heading_list) do
    local indent = string.rep("  ", heading.level - 1)
    local display = string.format("%s%s %s", indent, string.rep("#", heading.level), heading.text)
    table.insert(entries, {
      display = display,
      ordinal = heading.text,
      heading = heading,
    })
  end

  -- Create picker
  pickers
    .new({}, {
      prompt_title = "Table of Contents",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.ordinal,
            lnum = entry.heading.line_num,
          }
        end,
      }),
      sorter = conf.values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            utils.goto_line(selection.lnum)
          end
        end)
        return true
      end,
    })
    :find()

  return true
end

-- Setup Telekasten integration
function M.setup_telekasten_integration()
  local ok, telekasten = pcall(require, "telekasten")
  if not ok then
    return
  end

  -- Show integration message only once (after install/update)
  local cfg = config.get()
  if cfg.add_to_command_palette then
    local cache_dir = vim.fn.stdpath("cache") .. "/md_toc"
    local flag_file = cache_dir .. "/telekasten_msg_v" .. M.version

    -- Check if we've shown the message for this version
    if vim.fn.filereadable(flag_file) == 0 then
      vim.notify("md_toc: For Telekasten integration, add md_toc commands to your keybindings (see README)", vim.log.levels.INFO)

      -- Create cache dir and flag file
      vim.fn.mkdir(cache_dir, "p")
      local file = io.open(flag_file, "w")
      if file then
        file:write(M.version)
        file:close()
      end
    end
  end
end

-- Export internal modules for advanced usage
M.config = config
M.toc = toc
M.headings = headings
M.anchors = anchors
M.utils = utils

return M
