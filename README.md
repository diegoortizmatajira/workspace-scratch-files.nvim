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
    config = function()
        require('workspace-scratch-files').setup({
            -- Your configuration here
        })
    end
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

Once installed, the plugin will automatically manage scratch files for you
based on your configuration.

- **Global Scratch Files**: Files accessible across all workspaces.
- **Workspace Scratch Files**: Files specific to the current workspace directory.

### Example Commands

Below are examples of how to access the global and workspace scratch files:

#### Open Global Scratch File

```vim
:lua print(require('workspace-scratch-files.config').default.sources.global())
```

#### Open Workspace Scratch File

```vim
:lua print(require('workspace-scratch-files.config').default.sources.workspace())
```

---

## License

This plugin is released under the MIT License. See [LICENSE](./LICENSE) for more information.

---

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests for any feature requests or bug fixes.
