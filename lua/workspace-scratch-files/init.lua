local config = require("workspace-scratch-files.config")
local core = require("workspace-scratch-files.core")

local M = {}

function M.setup(opts)
	config.update(opts)
	-- Your setup code here
	-- Create user commands: ScratchDelete, ScratchSearch, ScratchNew, ScratchMigrate
	vim.api.nvim_create_user_command("ScratchNew", function()
		core.create_scratch_file()
	end, { nargs = 0 })
	vim.api.nvim_create_user_command("ScratchSearch", function()
		core.search_scratch_files()
	end, { nargs = 0 })
	vim.api.nvim_create_user_command("ScratchDelete", function(cmd)
		core.delete_scratch_file({ force = cmd.bang })
	end, { nargs = 0, bang = true })
	vim.api.nvim_create_user_command("ScratchMigrate", function()
		core.migrate_scratch_file()
	end, { nargs = 0 })
	vim.api.nvim_create_user_command("ScratchClipboard", function()
		core.open_clipboard_scratch_file()
	end, { nargs = 0 })
	vim.api.nvim_create_user_command("ScratchYankToClipboard", function()
		core.yank_to_clipboard_scratch_file()
	end, { nargs = 0, range = true })
	vim.api.nvim_create_user_command("ScratchPasteFromClipboard", function()
		core.paste_from_clipboard_scratch_file()
	end, { nargs = 0 })
end

return M
