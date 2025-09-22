--- @class Scratch.config
--- @field test_message string A test message for demonstration purposes.

local C = {
	--- Default configuration settings for the Scratch plugin.
	--- @type Scratch.config
	default = {
		test_message = "Hello from Scratch plugin!",
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
