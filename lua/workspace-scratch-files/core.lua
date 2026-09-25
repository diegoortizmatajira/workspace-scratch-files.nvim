local config = require("workspace-scratch-files.config")
local selector = require("workspace-scratch-files.selector")
local M = {}

--- @class Scratch.File
--- @field path string The full path to the scratch file.
--- @field icon string The icon associated with the scratch file.
--- @field icon_hl string The highlight group for the icon.
--- @field source string The source type of the scratch file (e.g., "global", "workspace").

--- @class Scratch.Source
--- @field path string The path to the source directory.
--- @field icon string The icon associated with the source.
--- @field icon_hl string The highlight group for the icon.
--- @field source string The name of the source.

--- Deletes a scratch file and cleans up its buffer.
--- @param item Scratch.File The scratch file to be deleted.
local function delete_file(item)
	local success, err = vim.uv.fs_unlink(item.path)
	if success then
		local bufnr = vim.fn.bufnr(item.path)
		if bufnr ~= -1 then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
		vim.notify("Deleted scratch file: " .. item.path)
	else
		vim.notify("Error deleting file: " .. err, vim.log.levels.ERROR)
	end
end

--- Prompts the user for confirmation before deleting a scratch file.
--- @param item Scratch.File The scratch file to be deleted.
--- @param force? boolean If true, skip confirmation prompt.
local function confirm_delete_file(item, force)
	if not item then
		return
	end
	if force then
		delete_file(item)
		return
	end
	vim.ui.input(
		{ prompt = "Are you sure you want to delete " .. vim.fn.fnamemodify(item.path, ":t") .. "? (y/n): " },
		function(input)
			if input and (input:lower() == "y" or input:lower() == "yes") then
				delete_file(item)
			else
				vim.notify("Deletion cancelled.", vim.log.levels.INFO)
			end
		end
	)
end

--- @param opts? { force: boolean }
function M.delete_scratch_file(opts)
	local force = opts and opts.force or false
	selector.select_file("Select a scratch file for deletion", function(item)
		confirm_delete_file(item, force)
	end)
end

function M.search_scratch_files()
	selector.select_file("Select a scratch file", function(item)
		if item then
			vim.cmd("edit " .. vim.fn.fnameescape(item.path))
		end
	end, confirm_delete_file)
end

--- Determines the configured source (scope) that owns the current buffer's file, if any.
--- @return Scratch.File? item The scratch file info for the current buffer, or nil if it's not a scratch file.
local function get_current_scratch_item()
	if not config.current then
		return nil
	end
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return nil
	end
	for source, path_or_func in pairs(config.current.sources) do
		local source_path = type(path_or_func) == "function" and path_or_func() or path_or_func
		if path:sub(1, #source_path) == source_path then
			return {
				path = path,
				icon = config.current.icons[source] or config.current.icons.default,
				icon_hl = config.current.highlight[source] or config.current.highlight.default,
				source = source,
			}
		end
	end
	return nil
end

--- Moves a scratch file to a different source (scope), keeping it open in its buffer.
--- @param item Scratch.File The scratch file to move.
--- @param target Scratch.Source The destination source.
local function move_scratch_file(item, target)
	local filename = vim.fn.fnamemodify(item.path, ":t")
	local new_path = target.path .. filename
	if vim.fn.filereadable(new_path) == 1 then
		vim.notify("A file already exists at the destination: " .. new_path, vim.log.levels.ERROR)
		return
	end
	vim.fn.mkdir(target.path, "p")
	local bufnr = vim.fn.bufnr(item.path)
	if bufnr ~= -1 then
		vim.api.nvim_buf_set_name(bufnr, new_path)
		vim.api.nvim_buf_call(bufnr, function()
			vim.cmd("silent! write!")
		end)
		vim.uv.fs_unlink(item.path)
		if vim.api.nvim_get_current_buf() ~= bufnr then
			vim.cmd("buffer " .. bufnr)
		end
	else
		local success, err = vim.uv.fs_rename(item.path, new_path)
		if not success then
			vim.notify("Error moving scratch file: " .. err, vim.log.levels.ERROR)
			return
		end
		vim.cmd("edit " .. vim.fn.fnameescape(new_path))
	end
	vim.notify(string.format("Moved scratch file to %s scope: %s", target.source, new_path))
end

--- Prompts the user to confirm migrating a scratch file to another scope, then performs the move.
--- @param item Scratch.File The scratch file to migrate.
local function confirm_migrate(item)
	local targets = selector.get_sources(item.source)
	if vim.tbl_isempty(targets) then
		vim.notify("No other scope configured to migrate to.", vim.log.levels.WARN)
		return
	end
	local function prompt_confirm(target)
		if not target then
			return
		end
		vim.ui.input({
			prompt = string.format(
				"Move %s from %s to %s scope? (y/n): ",
				vim.fn.fnamemodify(item.path, ":t"),
				item.source,
				target.source
			),
		}, function(input)
			if input and (input:lower() == "y" or input:lower() == "yes") then
				move_scratch_file(item, target)
			else
				vim.notify("Migration cancelled.", vim.log.levels.INFO)
			end
		end)
	end
	if #targets == 1 then
		prompt_confirm(targets[1])
	else
		selector.select_source(prompt_confirm, "Select target scope for migration", item.source)
	end
end

--- Migrates the current scratch file (or a selected one) to another scope.
--- If the current buffer is not a scratch file, prompts the user to select one first.
function M.migrate_scratch_file()
	local current_item = get_current_scratch_item()
	if current_item then
		confirm_migrate(current_item)
		return
	end
	selector.select_file("Select a scratch file to migrate", function(item)
		if item then
			confirm_migrate(item)
		end
	end)
end

local clipboard_filename = "Clipboard.txt"

--- Retrieves the full path to the global clipboard scratch file.
--- @return string? The path to the clipboard scratch file, or nil if the global source isn't configured.
local function get_clipboard_path()
	if not config.current then
		vim.notify("Configuration not found!", vim.log.levels.ERROR)
		return nil
	end
	local path_or_func = config.current.sources.global
	if not path_or_func then
		vim.notify("No 'global' source configured for the clipboard scratch file.", vim.log.levels.ERROR)
		return nil
	end
	local source_path = type(path_or_func) == "function" and path_or_func() or path_or_func
	return source_path .. clipboard_filename
end

--- Opens the global clipboard scratch file, creating it if it doesn't exist.
function M.open_clipboard_scratch_file()
	local path = get_clipboard_path()
	if not path then
		return
	end
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	if vim.fn.filereadable(path) == 0 then
		vim.fn.writefile({}, path)
	end
	vim.cmd("edit " .. vim.fn.fnameescape(path))
end

--- Yanks the current (or last) visual selection and overwrites the clipboard scratch file with it.
function M.yank_to_clipboard_scratch_file()
	local path = get_clipboard_path()
	if not path then
		return
	end
	-- <Cmd> mappings (as recommended in the README) keep Visual mode active
	-- instead of exiting it, so the selection is already live here and `gv`
	-- would wrongly reselect the *previous* area from stale '</'> marks.
	-- Only reselect with `gv` when we've already left Visual mode, e.g. when
	-- invoked via `:'<,'>ScratchYankToClipboard` from the command line.
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		vim.cmd([[normal! y]])
	else
		vim.cmd([[normal! gvy]])
	end
	local content = vim.fn.getreg('"'):gsub("\n$", "")
	local lines = vim.split(content, "\n", { plain = true })
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	vim.fn.writefile(lines, path)
	vim.notify("Yanked selection to clipboard scratch file: " .. path)
end

--- Copies the clipboard scratch file content into the system clipboard and pastes it in the current buffer.
function M.paste_from_clipboard_scratch_file()
	local path = get_clipboard_path()
	if not path then
		return
	end
	if vim.fn.filereadable(path) == 0 then
		vim.notify("Clipboard scratch file does not exist: " .. path, vim.log.levels.WARN)
		return
	end
	local lines = vim.fn.readfile(path)
	local content = table.concat(lines, "\n")
	local regtype = #lines > 1 and "l" or "c"
	vim.fn.setreg("+", content, regtype)
	vim.cmd([[normal! "+p]])
end

function M.create_scratch_file()
	selector.select_source(function(source)
		if not source then
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
			local is_new = vim.fn.filereadable(full_path) == 0
			if is_new then
				vim.fn.writefile({}, full_path)
			end
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))
			if is_new then
				vim.notify("Created new scratch file: " .. full_path)
			else
				vim.notify("Opened existing scratch file: " .. full_path, vim.log.levels.INFO)
			end
		end)
	end, "Select the scope for the new scratch file")
end

return M
