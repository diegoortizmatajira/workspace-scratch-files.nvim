local config = require("workspace-scratch-files.config")
local M = {}

--- Retrieves all files from the specified source path.
--- @param source_path string The path to the source directory.
--- @param icon string The icon associated with the source.
--- @param source string The name of the source.
--- @return Scratch.File[] A list of scratch files found in the source directory.
local function get_scratches_from(source_path, icon, source)
	-- Use vim.fn.glob to get all files in the directory
	local files = vim.fn.glob(source_path .. "*", false, true)
	local scratch_files = {}
	for _, file in ipairs(files) do
		table.insert(scratch_files, {
			path = file,
			icon = icon,
			source = source,
		})
	end
	return scratch_files
end

--- Retrieves all scratch files from all configured sources.
--- @return Scratch.File[]? A list of all scratch files from all sources.
local function get_all_scratches()
	if not config.current then
		vim.notify("Configuration not found!", vim.log.levels.ERROR)
		return nil
	end
	local all_files = {}
	for source, path_or_func in pairs(config.current.sources) do
		local path = type(path_or_func) == "function" and path_or_func() or path_or_func
		local icon = config.current.icons[source] or config.current.icons.default
		local files = get_scratches_from(path, icon, source)
		vim.list_extend(all_files, files)
	end
	if vim.tbl_isempty(all_files) then
		vim.notify("No scratch files found.", vim.log.levels.WARN)
		return nil
	end
	return all_files
end

--- Prompts the user to select a scratch file from all available sources and opens it.
--- If no configuration is found or no scratch files are available, appropriate notifications are shown.
--- @param title string The title for the selection prompt.
--- @param callback fun(file: Scratch.File) A callback function to be called with the selected file.
--- @param delete_callback fun(file: Scratch.File)? An optional callback function to be called for deleting a file.
local function select_file_with_telescope(title, callback, delete_callback)
	local has_telescope, _ = pcall(require, "telescope")
	if not has_telescope then
		return false
	end
	local all_files = get_all_scratches()
	if all_files then
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local conf = require("telescope.config").values
		local entry_display = require("telescope.pickers.entry_display")
		local utils = require("telescope.utils")
		-- Define how each entry will be displayed
		local displayer = entry_display.create({
			separator = " ",
			items = {
				{ width = 2 },
				{},
				{},
				{ remaining = true },
			},
		})
		-- Custom display function to show icon and source name
		local make_display = function(entry)
			local _, icon_hl, icon = utils.transform_devicons(entry.value.path, "", false) -- to get the correct icon based on file type
			return displayer({
				{ entry.value.icon, "TelescopeResultsFunction" },
				{ icon or " ", icon_hl },
				vim.fn.fnamemodify(entry.value.path, ":t"),
				{ entry.value.source or "", "TelescopeResultsComment" },
			})
		end
		local selector = function(opts)
			opts = opts or {}
			pickers
				.new(opts, {
					prompt_title = title or "Select Scratch File",
					finder = finders.new_table({
						results = all_files,
						entry_maker = function(entry)
							return {
								value = entry,
								path = entry.path,
								display = make_display,
								ordinal = entry.path,
							}
						end,
					}),
					previewer = conf.file_previewer(opts),
					sorter = conf.generic_sorter(opts),
					attach_mappings = function(prompt_bufnr, map)
						actions.select_default:replace(function()
							actions.close(prompt_bufnr)
							local selection = action_state.get_selected_entry()
							if selection then
								callback(selection.value)
							end
						end)
						if delete_callback then
							local delete_scratch_file = function()
								actions.close(prompt_bufnr)
								local selection = action_state.get_selected_entry()
								if selection then
									delete_callback(selection.value)
								end
							end
							map({ "i", "n" }, "<c-d>", delete_scratch_file)
						end
						return true
					end,
				})
				:find()
		end
		-- to execute the function
		selector()
	end
	return true
end

--- Prompts the user to select a scratch file from all available sources and opens it.
--- If no configuration is found or no scratch files are available, appropriate notifications are shown.
--- @param title string The title for the selection prompt.
--- @param callback fun(file: Scratch.File) A callback function to be called with the selected file.
--- @param delete_callback fun(file: Scratch.File)? An optional callback function to be called for deleting a file.
function M.select_file(title, callback, delete_callback)
	if select_file_with_telescope(title, callback, delete_callback) then
		return
	end
	-- Fallback to vim.ui.select if Telescope is not available
	local all_files = get_all_scratches()
	if all_files then
		vim.ui.select(all_files, {
			prompt = title or "Select Scratch File:",
			format_item = function(item)
				return string.format("%s %s (%s)", item.icon, vim.fn.fnamemodify(item.path, ":t"), item.source)
			end,
		}, callback)
	end
end

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

--- Prompts the user to select a source for creating a new scratch file using Telescope.
--- If no configuration is found, an appropriate notification is shown.
--- @param callback fun(source: Scratch.Source) A callback function to be called with the selected source.
--- @param title string The title for the selection prompt.
local function select_source_with_telescope(callback, title)
	local has_telescope, _ = pcall(require, "telescope")
	if not has_telescope then
		return false
	end
	local sources = get_sources()
	if vim.tbl_isempty(sources) then
		vim.notify("No sources configured!", vim.log.levels.ERROR)
		return true
	end
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local themes = require("telescope.themes")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values
	local entry_display = require("telescope.pickers.entry_display")
	-- Define how each entry will be displayed
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 2 },
			{ remaining = true },
		},
	})
	-- Custom display function to show icon and source name
	local make_display = function(entry)
		return displayer({
			{ entry.value.icon, "TelescopeResultsFunction" },
			entry.value.source,
		})
	end
	local selector = function(opts)
		opts = opts or {}
		pickers
			.new(opts, {
				prompt_title = title,
				finder = finders.new_table({
					results = sources,
					entry_maker = function(entry)
						return {
							value = entry,
							path = entry.path,
							-- display = string.format("%s %s", entry.icon, entry.source),
							display = make_display,
							ordinal = entry.source,
						}
					end,
				}),
				sorter = conf.generic_sorter(opts),
				attach_mappings = function(prompt_bufnr)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						if selection then
							callback(selection.value)
						end
					end)
					return true
				end,
			})
			:find()
	end
	-- to execute the function
	selector(themes.get_dropdown({}))
	return true
end

--- Prompts the user to select a source for creating a new scratch file.
--- If no configuration is found, an appropriate notification is shown.
--- @param callback fun(source: Scratch.Source) A callback function to be called with the selected source.
--- @param title? string The title for the selection prompt.
function M.select_source(callback, title)
	title = title or "Select Scratch File Source"
	if select_source_with_telescope(callback, title) then
		return
	end
	vim.ui.select(get_sources(), {
		prompt = title,
		format_item = function(item)
			return string.format("%s %s", item.icon, item.source)
		end,
	}, callback)
end
return M
