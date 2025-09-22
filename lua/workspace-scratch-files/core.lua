local M = {}

function M.delete_scratch_file(file_path)
	vim.notify("Deleting scratch file: " .. file_path)
end

function M.search_scratch_files()
	vim.notify("Searching scratch files...")
end

function M.create_scratch_file()
	vim.notify("Creating a new scratch file...")
end

return M
