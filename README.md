# workspace-scratch-files.nvim

A Neovim plugin for managing scratch files both globally and per workspace.

Read about how it was created in my [Blog post](https://diego-ortiz.me/posts/how_to_neovim_plugin/)

---

## Features

- **Global Scratch Files**: Store scratch notes accessible across all your
  Neovim sessions.
- **Workspace-specific Scratch Files**: Unique scratch files for each
  workspace, identified by directory name and hash.
- **Customizable Icons and Highlights**: Visual differentiation for global and
  workspace sources with configurable highlight groups.
- **Telescope Integration**: Optional integration for rich selection with file
  preview, colored icons, and `<c-d>` shortcut to delete files from the search
  picker.
- **Fallback UI**: Works without Telescope using `vim.ui.select`.

---

## Requirements

- Neovim >= 0.10
- Optional: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced file picker with preview and icons
- Optional: [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) for file type icons in the Telescope picker

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
            local custom_name = string.format("%s-%s", last_folder,
                string.sub(hashed, 1, 8))
            return vim.fn.stdpath("data") .. "/ws-scratches/" .. custom_name .. "/"
        end,
    },
    icons = {
        global = "󰥨 ",
        workspace = "󱧶 ",
        default = "󰚝 ",
    },
    highlight = {
        global = "Function",
        workspace = "Number",
        default = "Operator",
    },
}
```

### Customizing Configuration

You can override the default configuration by passing your custom settings to
the `setup` function. Sources can be either strings (static paths) or functions
(evaluated at runtime):

```lua
require('workspace-scratch-files').setup({
    sources = {
        global = "~/my-global-scratches/",
        workspace = function()
            return vim.fn.getcwd() .. "/.my-scratches/"
        end,
    },
    icons = {
        global = "G ",
        workspace = "W ",
        default = "? ",
    },
    highlight = {
        global = "DiagnosticInfo",
        workspace = "DiagnosticHint",
        default = "Comment",
    },
})
```

---

## Usage

### Commands

| Command | Description |
|---|---|
| `:ScratchNew` | Create a new scratch file. Prompts for scope (global/workspace) and filename. |
| `:ScratchSearch` | Search and open existing scratch files. With Telescope, press `<c-d>` to delete. |
| `:ScratchDelete` | Select and delete a scratch file (with confirmation). |
| `:ScratchDelete!` | Select and delete a scratch file (skips confirmation). |

### Suggested Keymaps

```lua
vim.keymap.set("n", "<leader>sn", "<cmd>ScratchNew<cr>", { desc = "New scratch file" })
vim.keymap.set("n", "<leader>ss", "<cmd>ScratchSearch<cr>", { desc = "Search scratch files" })
vim.keymap.set("n", "<leader>sd", "<cmd>ScratchDelete<cr>", { desc = "Delete scratch file" })
```

---

## Running Tests

Tests use [plenary.nvim](https://github.com/nvim-telescope/plenary.nvim). Run
them from within Neovim:

```vim
:PlenaryBustedDirectory test/
```

---

## License

This plugin is released under the MIT License. See [LICENSE](./LICENSE) for
more information.

---

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests
for any feature requests or bug fixes.
