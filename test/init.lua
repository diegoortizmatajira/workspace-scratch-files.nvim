--- You will be adding your plugin code the runtime path (to use it without a
--- plugin manager)

vim.opt.runtimepath:prepend(vim.fn.getcwd())

local plugin = require("workspace-scratch-files")
plugin.setup({
    test_message = "This is a custom test message!",
})
