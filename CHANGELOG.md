# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-10

### Added
- Initial release of md_toc
- Generate table of contents for markdown files
- Support for multiple markdown anchor styles:
  - GFM (GitHub Flavored Markdown)
  - GitLab
  - Redcarpet
  - Marked
- TOC generation with fence markers
- Update existing TOC
- Remove TOC from buffer
- Jump to heading from TOC entry (`:MdTocGoto`)
- Telescope integration for TOC navigation (`:MdTocNav`)
- Optional auto-update on save
- Configurable options:
  - List markers
  - Indentation size
  - Min/max heading levels
  - Fence text customization
- Support for both ATX and Setext heading styles
- Code block detection (skips headings in code)
- Telekasten integration support
- Comprehensive documentation and README
- MIT License

### Commands
- `:MdTocGenerate` - Generate new TOC at cursor
- `:MdTocUpdate` - Update existing TOC
- `:MdTocRemove` - Remove TOC from buffer
- `:MdTocGoto` - Jump to heading under cursor
- `:MdTocNav` - Navigate headings with Telescope

### Configuration
- Lua-based configuration via `require('md_toc').setup({})`
- Default GFM anchor style
- Customizable list markers and indentation
- Optional auto-update behavior
- Telescope and Telekasten integration toggles

[1.0.0]: https://github.com/D3alWyth1T/md_toc/releases/tag/v1.0.0
