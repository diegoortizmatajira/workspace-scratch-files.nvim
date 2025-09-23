local config = require("workspace-scratch-files.config")
local selector = require("workspace-scratch-files.selector")
local M = {}

--- @class Scratch.File
--- @field path string The full path to the scratch file.
--- @field icon string The icon associated with the scratch file.
--- @field source string The source type of the scratch file (e.g., "global", "workspace").

--- @class Scratch.Source
--- @field path string The path to the source directory.
--- @field icon string The icon associated with the source.
--- @field source string The name of the source.

--- Retrieves all configured sources for scratch files.
--- @return Scratch.Source[] A list of sources with their paths and icons.
local function get_sources()
	local sources = {}
	for source, path_or_func in pairs(config.current.sources) do
		local path = type(path_or_func) == "function" and path_or_func() or path_or_func
		local icon = config.current.icons[source] or config.current.icons.default
		table.insert(sources, {
			path = path,
			icon = icon,
			source = source,
		})
	end
	return sources
end

--- Prompts the user for confirmation before deleting a scratch file.
--- @param item Scratch.File The scratch file to be deleted.
local function confirm_delete_file(item)
	if item then
		vim.ui.input(
			{ prompt = "Are you sure you want to delete " .. vim.fn.fnamemodify(item.path, ":t") .. "? (y/n): " },
			function(input)
				if input and (input:lower() == "y" or input:lower() == "yes") then
					local success, err = os.remove(item.path)
					if success then
						vim.notify("Deleted scratch file: " .. item.path)
					else
						vim.notify("Error deleting file: " .. err, vim.log.levels.ERROR)
					end
				else
					vim.notify("Deletion cancelled.", vim.log.levels.INFO)
				end
			end
		)
	end
end

function M.delete_scratch_file()
	selector.select_file("Select a scratch file for deletion", confirm_delete_file)
end

function M.search_scratch_files()
	selector.select_file("Select a scratch file", function(item)
		if item then
			vim.cmd("edit " .. item.path)
		end
	end, confirm_delete_file)
end

function M.create_scratch_file()
	vim.notify("Creating a new scratch file...")
	vim.ui.select(get_sources(), {
		prompt = "Select Scratch File Source:",
		format_item = function(item)
			return string.format("%s %s", item.icon, item.source)
		end,
	}, function(source)
		if not source then
			vim.notify("Scratch file creation cancelled.", vim.log.levels.WARN)
			return
		end
		vim.ui.input({ prompt = "Enter scratch file name: " }, function(input)
			if not input or input == "" then
				vim.notify("Invalid file name. Scratch file creation cancelled.", vim.log.levels.ERROR)
				return
			end
			local full_path = source.path .. input
			-- Ensure the directory exists
			vim.fn.mkdir(vim.fn.fnamemodify(full_path, ":h"), "p")
			-- Create the file if it doesn't exist and open it
			if vim.fn.filereadable(full_path) == 0 then
				vim.fn.writefile({}, full_path)
			end
			vim.cmd("edit " .. full_path)
			vim.notify("Created new scratch file: " .. full_path)
		end)
	end)
end

return M
