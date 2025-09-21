vim.opt.runtimepath:prepend(vim.fn.getcwd())

local plugin = require("workspace-scratch-files")
plugin.setup()
