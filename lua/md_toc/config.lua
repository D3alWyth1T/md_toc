-- config.lua - Configuration management for md_toc
local M = {}

-- Default configuration
M.defaults = {
  -- TOC generation options
  style = "gfm", -- gfm, gitlab, redcarpet, marked
  list_marker = "*", -- Character for list items
  cycle_list_markers = false, -- Cycle through *, -, + for different levels
  indent_size = 4, -- Number of spaces per indentation level
  min_level = 1, -- Minimum heading level to include
  max_level = 6, -- Maximum heading level to include

  -- Fence options
  fence_text = "md_toc", -- Text to use in fence comments
  dont_insert_fence = false, -- Don't insert fence markers

  -- Auto-update options
  auto_update = false, -- Auto-update TOC on save

  -- Telekasten integration
  telekasten_integration = true, -- Enable Telekasten integration if available
  add_to_command_palette = true, -- Add commands to Telekasten command palette

  -- Navigation options
  telescope_navigation = true, -- Use Telescope for TOC navigation if available
}

-- Current configuration (will be merged with defaults)
M.config = vim.deepcopy(M.defaults)

-- Setup function to configure the plugin
function M.setup(user_config)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  -- Validate configuration
  M.validate()

  return M.config
end

-- Validate configuration
function M.validate()
  local config = M.config

  -- Validate style
  local valid_styles = { gfm = true, gitlab = true, redcarpet = true, marked = true }
  if not valid_styles[config.style] then
    vim.notify(
      string.format("Invalid style '%s', using 'gfm'. Valid styles: gfm, gitlab, redcarpet, marked", config.style),
      vim.log.levels.WARN
    )
    config.style = "gfm"
  end

  -- Validate list_marker
  if type(config.list_marker) ~= "string" or #config.list_marker ~= 1 then
    vim.notify("Invalid list_marker, using '*'", vim.log.levels.WARN)
    config.list_marker = "*"
  end

  -- Validate indent_size
  if type(config.indent_size) ~= "number" or config.indent_size < 0 then
    vim.notify("Invalid indent_size, using 4", vim.log.levels.WARN)
    config.indent_size = 4
  end

  -- Validate heading levels
  if type(config.min_level) ~= "number" or config.min_level < 1 or config.min_level > 6 then
    vim.notify("Invalid min_level, using 1", vim.log.levels.WARN)
    config.min_level = 1
  end

  if type(config.max_level) ~= "number" or config.max_level < 1 or config.max_level > 6 then
    vim.notify("Invalid max_level, using 6", vim.log.levels.WARN)
    config.max_level = 6
  end

  if config.min_level > config.max_level then
    vim.notify("min_level cannot be greater than max_level, swapping values", vim.log.levels.WARN)
    config.min_level, config.max_level = config.max_level, config.min_level
  end
end

-- Get current configuration
function M.get()
  return M.config
end

-- Get a specific config value
function M.get_value(key)
  return M.config[key]
end

-- Set a specific config value
function M.set_value(key, value)
  M.config[key] = value
end

return M
