local config = require("workspace-scratch-files.config")
local core = require("workspace-scratch-files.core")

local M = {}

function M.setup(opts)
	config.update(opts)
	-- Your setup code here
	-- Create user commands: ScratchDelete, ScratchSearch, ScratchNew
	vim.api.nvim_create_user_command("ScratchNew", function()
		core.create_scratch_file()
	end, { nargs = 0 })
	vim.api.nvim_create_user_command("ScratchSearch", function()
		core.search_scratch_files()
	end, { nargs = 0 })
	vim.api.nvim_create_user_command("ScratchDelete", function()
		core.delete_scratch_file()
	end, { nargs = 0 })
end

return M
