--- @class Scratch.config
--- @field sources table<string, string|fun():string> A table containing source paths for scratch files.
--- @field icons table<string, string> A table containing icons for different scratch file sources.

local folder = "/ws-scratches"
--- Retrieves the path for the workspace-specific scratch file source.
--- This function constructs a unique directory path based on the current working directory.
--- The uniqueness is achieved by combining the last folder name of the current working directory
--- with the first 8 characters of its SHA-256 hash.
--- @return string The path to the workspace-specific scratch file source.
local function get_workspace_source()
	local cwd = vim.fn.getcwd()
	-- Get the last folder name of the current working directory
	local last_folder = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	-- Hash the current working directory to ensure uniqueness
	local hashed = vim.fn.sha256(cwd)
	-- Create a custom name using the last folder and the first 8 characters of the hash
	local custom_name = string.format("%s - %s", last_folder, string.sub(hashed, 1, 8))
	return vim.fn.stdpath("data") .. folder .. "/" .. custom_name .. "/"
end

--- Retrieves the path for the global scratch file source.
--- This function returns the default directory path where global scratch files are stored.
--- The path is based on the standard data directory of Neovim.
--- @return string The path to the global scratch file source.
local function get_global_source()
	return vim.fn.stdpath("data") .. folder .. "/global/"
end

local C = {
	--- Default configuration settings for the Scratch plugin.
	--- @type Scratch.config
	default = {
		sources = {
			global = get_global_source,
			workspace = get_workspace_source,
		},
		icons = {
			global = "🌐",
			workspace = " ",
			default = "󰚝 ",
		},
	},
	--- Current configuration settings for the Scratch plugin.
	--- @type Scratch.config?
	current = nil,
}

--- Updates the current configuration with a new configuration.
--- If the provided configuration is not a table or is nil, the update is ignored.
--- @param new_config? Scratch.config new configuraton to be applied
function C.update(new_config)
	--- Initializes or overrides the current configuration with the new configuration.
	--- If no current configuration exists, it defaults to the default configuration.
	C.current = vim.tbl_deep_extend("force", C.current or C.default, new_config or {})
end

return C
