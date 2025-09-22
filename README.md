# workspace-scratch-files.nvim

A Neovim plugin for managing scratch files both globally and per workspace.

---

## Features

- **Global Scratch Files**: Store scratch notes accessible across all your
  Neovim sessions.
- **Workspace-specific Scratch Files**: Unique scratch files for each
  workspace.
- **Customizable Icons**: Visual differentiation for global and workspace
  sources.

---

## Installation

You can install this plugin using your preferred plugin manager. Below are
examples for popular plugin managers:

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'diegoortizmatajira/workspace-scratch-files.nvim',
    config = function()
        require('workspace-scratch-files').setup({
            -- Your configuration here
        })
    end
}
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'diegoortizmatajira/workspace-scratch-files.nvim',
    opts = {
            -- Your configuration here
        },
}
```

---

## Configuration

The plugin provides a default configuration that you can customize:

### Default Configuration

```lua
{
    sources = {
        global = function()
            return vim.fn.stdpath("data") .. "/ws-scratches/global/"
        end,
        workspace = function()
            local cwd = vim.fn.getcwd()
            local last_folder = vim.fn.fnamemodify(cwd, ":t")
            local hashed = vim.fn.sha256(cwd)
            local custom_name = string.format("%s - %s", last_folder,
                string.sub(hashed, 1, 8))
            return vim.fn.stdpath("data") .. "/ws-scratches/" .. custom_name .. "/"
        end,
    },
    icons = {
        global = "🌐",
        workspace = "",
        default = "󰚝",
    },
}
```

### Customizing Configuration

You can override the default configuration by passing your custom settings to
the `setup` function:

```lua
require('workspace-scratch-files').setup({
    sources = {
        global = "~/my-global-scratches/",
        workspace = function()
            return vim.fn.getcwd() .. "/.my-scratches/"
        end,
    },
    icons = {
        global = "🌍",
        workspace = "🏢",
        default = "📝",
    },
})
```

---

## Usage

### Available Commands

- **ScratchNew**: Create a new scratch file.
- **ScratchSearch**: Search existing scratch files.
- **ScratchDelete**: Delete a specific scratch file.

To use these commands, simply type them in Neovim's command mode (e.g., `:ScratchNew`).

---

## License

This plugin is released under the MIT License. See [LICENSE](./LICENSE) for
more information.

---

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests
for any feature requests or bug fixes.
