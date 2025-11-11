# md_toc

A Neovim plugin for generating and managing table of contents in markdown files. Designed to work seamlessly with [Telekasten](https://github.com/nvim-telekasten/telekasten.nvim) but works independently as well.

## Features

- Generate table of contents from markdown headings
- Support for multiple markdown flavors:
  - GFM (GitHub Flavored Markdown)
  - GitLab
  - Redcarpet
  - Marked
- Pleasant looking anchor links for internal file references
- Optional Telescope integration for TOC navigation
- Auto-update TOC on save (optional)
- Works with both ATX (`# Heading`) and Setext heading styles
- Respects code blocks (won't include headings from code)
- Configurable indentation, list markers, and heading levels

## Installation

### Using Packer

```lua
use {
  'd3al/md_toc',
  config = function()
    require('md_toc').setup({
      -- Optional configuration (these are the defaults)
      style = 'gfm',              -- gfm, gitlab, redcarpet, marked
      list_marker = '*',          -- Character for list items
      indent_size = 4,            -- Spaces per indentation level
      min_level = 1,              -- Minimum heading level to include
      max_level = 6,              -- Maximum heading level to include
      auto_update = false,        -- Auto-update TOC on save
      fence_text = 'md_toc',      -- Text to use in fence comments
      telescope_navigation = true, -- Use Telescope for navigation
      telekasten_integration = true, -- Enable Telekasten integration
    })
  end
}
```

### Using lazy.nvim

```lua
{
  'd3al/md_toc',
  ft = 'markdown',
  config = function()
    require('md_toc').setup()
  end
}
```

### Using vim-plug

```vim
Plug 'd3al/md_toc'

lua << EOF
require('md_toc').setup()
EOF
```

## Usage

### Commands

- `:MdTocGenerate` - Generate a new table of contents at cursor position
- `:MdTocUpdate` - Update existing table of contents
- `:MdTocRemove` - Remove table of contents from buffer
- `:MdTocGoto` - Jump to heading under cursor (when cursor is on TOC entry)
- `:MdTocNav` - Open Telescope picker to navigate headings (requires Telescope)

### Example Workflow

1. Open a markdown file
2. Position cursor where you want the TOC
3. Run `:MdTocGenerate`

The plugin will generate a TOC like this:

```markdown
<!-- md_toc GFM -->

* [Introduction](#introduction)
* [Getting Started](#getting-started)
    * [Installation](#installation)
    * [Configuration](#configuration)
* [Advanced Usage](#advanced-usage)
    * [Custom Styles](#custom-styles)

<!-- md_toc -->
```

### Auto-Update

Enable auto-update to automatically refresh the TOC when you save:

```lua
require('md_toc').setup({
  auto_update = true,
})
```

### Telescope Navigation

If Telescope is installed, use `:MdTocNav` to open a searchable list of all headings:

```lua
-- Optional: Add a keybinding
vim.keymap.set('n', '<leader>mt', '<cmd>MdTocNav<cr>', { desc = 'Navigate TOC' })
```

## Configuration

### Complete Configuration Example

```lua
require('md_toc').setup({
  -- Anchor link style
  style = 'gfm',  -- 'gfm', 'gitlab', 'redcarpet', 'marked'

  -- List formatting
  list_marker = '*',           -- Character for list items
  cycle_list_markers = false,  -- Use *, -, + for different levels
  indent_size = 4,             -- Spaces per indentation level

  -- Heading level filtering
  min_level = 1,  -- Include headings from level 1...
  max_level = 6,  -- ...through level 6

  -- Fence markers
  fence_text = 'md_toc',      -- Text in fence comments
  dont_insert_fence = false,   -- Set true to omit fence markers

  -- Auto-update behavior
  auto_update = false,  -- Auto-update on save

  -- Integration
  telekasten_integration = true,   -- Enable Telekasten integration
  telescope_navigation = true,     -- Enable Telescope navigation
})
```

### Markdown Styles

Different markdown processors generate anchors differently:

**GFM (GitHub Flavored Markdown)**
- Default style, works with GitHub, Obsidian, and most modern parsers
- `"Chapter One"` → `#chapter-one`
- Preserves Unicode characters: `"第三章"` → `#第三章`

**GitLab**
- Similar to GFM with slightly different special character handling
- Consolidates multiple hyphens
- Strips leading/trailing underscores

**Redcarpet**
- Ruby markdown processor
- HTML entity encoding for some characters
- `"Q & A"` → `#q-&amp;-a`

**Marked**
- JavaScript markdown processor
- Minimal character transformation
- Simpler anchor generation

## Telekasten Integration

The plugin works great with Telekasten! It automatically detects when Telekasten is installed and can integrate with it.

### Recommended Telekasten Configuration

```lua
-- In your Telekasten setup
require('telekasten').setup({
  home = vim.fn.expand("~/zettelkasten"),
  -- ... other Telekasten config
})

-- Setup md_toc
require('md_toc').setup({
  telekasten_integration = true,
})

-- Optional: Add keybindings
vim.keymap.set('n', '<leader>zt', '<cmd>MdTocGenerate<cr>', { desc = 'Generate TOC' })
vim.keymap.set('n', '<leader>zu', '<cmd>MdTocUpdate<cr>', { desc = 'Update TOC' })
```

## Advanced Usage

### Programmatic API

You can also use the plugin programmatically in Lua:

```lua
local md_toc = require('md_toc')

-- Generate TOC
md_toc.generate()

-- Update TOC
md_toc.update()

-- Remove TOC
md_toc.remove()

-- Navigate to heading
md_toc.goto()

-- Access internal modules
local headings = md_toc.headings.extract_headings(0, config)
local anchor = md_toc.anchors.generate("My Heading", "gfm", {})
```

### Custom Keybindings

```lua
-- Basic bindings
vim.keymap.set('n', '<leader>tg', '<cmd>MdTocGenerate<cr>', { desc = 'Generate TOC' })
vim.keymap.set('n', '<leader>tu', '<cmd>MdTocUpdate<cr>', { desc = 'Update TOC' })
vim.keymap.set('n', '<leader>tr', '<cmd>MdTocRemove<cr>', { desc = 'Remove TOC' })
vim.keymap.set('n', '<leader>tn', '<cmd>MdTocNav<cr>', { desc = 'Navigate TOC' })

-- Quick jump from TOC entry
vim.keymap.set('n', 'gf', function()
  local line = vim.api.nvim_get_current_line()
  if line:match('%[.-%]%(#.-%)') then
    vim.cmd('MdTocGoto')
  else
    vim.cmd('normal! gf')
  end
end, { buffer = true, desc = 'Follow link or TOC entry' })
```

## Comparison with vim-markdown-toc

This plugin is inspired by [vim-markdown-toc](https://github.com/mzlogin/vim-markdown-toc) but offers:

- Written in Lua for modern Neovim
- Better integration with Neovim ecosystem (Telescope, Lua API)
- Built-in Telekasten support
- Simplified configuration using Lua tables
- Active development for Neovim-specific features

## Requirements

- Neovim 0.7.0 or later
- Optional: [Telescope](https://github.com/nvim-telescope/telescope.nvim) for enhanced navigation
- Optional: [Telekasten](https://github.com/nvim-telekasten/telekasten.nvim) for note-taking integration

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

- Inspired by [vim-markdown-toc](https://github.com/mzlogin/vim-markdown-toc)
- Designed to complement [Telekasten](https://github.com/nvim-telekasten/telekasten.nvim)
