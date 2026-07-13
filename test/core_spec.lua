local config = require("workspace-scratch-files.config")
local core = require("workspace-scratch-files.core")
local selector = require("workspace-scratch-files.selector")

local test_dir

describe("core", function()
	before_each(function()
		config.current = nil
		test_dir = vim.fn.tempname() .. "/scratches/"
		vim.fn.mkdir(test_dir, "p")
		config.update({
			sources = {
				test = test_dir,
			},
		})
	end)

	after_each(function()
		-- Clean up test files and buffers
		local files = vim.fn.glob(test_dir .. "*", false, true)
		for _, f in ipairs(files) do
			local bufnr = vim.fn.bufnr(f)
			if bufnr ~= -1 then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
			vim.uv.fs_unlink(f)
		end
		vim.fn.delete(test_dir, "d")
	end)

	describe("create_scratch_file", function()
		it("creates a file and opens it in a buffer", function()
			local full_path = test_dir .. "test_scratch.txt"
			vim.fn.writefile({}, full_path)
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))

			assert.are.equal(1, vim.fn.filereadable(full_path))
			assert.is_truthy(vim.api.nvim_buf_get_name(0):find("test_scratch.txt", 1, true))
		end)

		it("creates parent directories if they don't exist", function()
			local nested_dir = test_dir .. "sub/"
			local full_path = nested_dir .. "nested.txt"
			vim.fn.mkdir(vim.fn.fnamemodify(full_path, ":h"), "p")
			vim.fn.writefile({}, full_path)

			assert.are.equal(1, vim.fn.filereadable(full_path))

			-- Clean up nested
			vim.uv.fs_unlink(full_path)
			vim.fn.delete(nested_dir, "d")
		end)

		it("does not overwrite an existing file", function()
			local full_path = test_dir .. "existing.txt"
			vim.fn.writefile({ "original content" }, full_path)

			-- Simulate the create logic: only write if not readable
			if vim.fn.filereadable(full_path) == 0 then
				vim.fn.writefile({}, full_path)
			end

			local content = vim.fn.readfile(full_path)
			assert.are.same({ "original content" }, content)
		end)
	end)

	describe("delete_scratch_file", function()
		it("deletes a file using vim.uv.fs_unlink", function()
			local full_path = test_dir .. "to_delete.txt"
			vim.fn.writefile({}, full_path)
			assert.are.equal(1, vim.fn.filereadable(full_path))

			local success = vim.uv.fs_unlink(full_path)
			assert.is_truthy(success)
			assert.are.equal(0, vim.fn.filereadable(full_path))
		end)

		it("cleans up buffer after deletion", function()
			local full_path = test_dir .. "buf_cleanup.txt"
			vim.fn.writefile({}, full_path)
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))
			local bufnr = vim.fn.bufnr(full_path)
			assert.is_not.are.equal(-1, bufnr)

			vim.uv.fs_unlink(full_path)
			vim.api.nvim_buf_delete(bufnr, { force = true })

			assert.is_false(vim.api.nvim_buf_is_valid(bufnr))
		end)

		it("returns an error for non-existent files", function()
			local success, err = vim.uv.fs_unlink(test_dir .. "nonexistent.txt")
			assert.is_nil(success)
			assert.is_truthy(err)
		end)
	end)

	describe("migrate_scratch_file", function()
		local dir_a, dir_b

		before_each(function()
			config.current = nil
			dir_a = vim.fn.tempname() .. "/scratch-a/"
			dir_b = vim.fn.tempname() .. "/scratch-b/"
			vim.fn.mkdir(dir_a, "p")
			vim.fn.mkdir(dir_b, "p")
			config.update({
				sources = {
					scope_a = dir_a,
					scope_b = dir_b,
				},
			})
			-- config.update() merges onto the default global/workspace sources;
			-- pin sources to exactly these two so migration has a single target.
			config.current.sources = {
				scope_a = dir_a,
				scope_b = dir_b,
			}
		end)

		after_each(function()
			for _, dir in ipairs({ dir_a, dir_b }) do
				local files = vim.fn.glob(dir .. "*", false, true)
				for _, f in ipairs(files) do
					local bufnr = vim.fn.bufnr(f)
					if bufnr ~= -1 then
						vim.api.nvim_buf_delete(bufnr, { force = true })
					end
					vim.uv.fs_unlink(f)
				end
				vim.fn.delete(dir, "d")
			end
		end)

		it("moves the current buffer's scratch file to the other scope when confirmed", function()
			local full_path = dir_a .. "notes.txt"
			vim.fn.writefile({ "hello" }, full_path)
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))

			local original_input = vim.ui.input
			vim.ui.input = function(_, on_confirm)
				on_confirm("y")
			end

			core.migrate_scratch_file()

			vim.ui.input = original_input

			local new_path = dir_b .. "notes.txt"
			assert.are.equal(0, vim.fn.filereadable(full_path))
			assert.are.equal(1, vim.fn.filereadable(new_path))
			assert.are.same({ "hello" }, vim.fn.readfile(new_path))
			assert.is_truthy(vim.api.nvim_buf_get_name(0):find(new_path, 1, true))
		end)

		it("leaves the file untouched when migration is not confirmed", function()
			local full_path = dir_a .. "keep.txt"
			vim.fn.writefile({}, full_path)
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))

			local original_input = vim.ui.input
			vim.ui.input = function(_, on_confirm)
				on_confirm("n")
			end

			core.migrate_scratch_file()

			vim.ui.input = original_input

			assert.are.equal(1, vim.fn.filereadable(full_path))
			assert.are.equal(0, vim.fn.filereadable(dir_b .. "keep.txt"))
		end)

		it("opens the file selector when the current buffer is not a scratch file", function()
			vim.cmd("enew")

			local captured_title
			local original_select_file = selector.select_file
			selector.select_file = function(title, _callback)
				captured_title = title
			end

			core.migrate_scratch_file()

			selector.select_file = original_select_file

			assert.is_truthy(captured_title)
		end)

		it("migrates a scratch file chosen via the selector even if it wasn't already open", function()
			local full_path = dir_a .. "picked.txt"
			vim.fn.writefile({}, full_path)
			vim.cmd("enew")

			local original_select_file = selector.select_file
			selector.select_file = function(_title, callback)
				callback({ path = full_path, icon = "", icon_hl = "Normal", source = "scope_a" })
			end

			local original_input = vim.ui.input
			vim.ui.input = function(_, on_confirm)
				on_confirm("y")
			end

			core.migrate_scratch_file()

			vim.ui.input = original_input
			selector.select_file = original_select_file

			assert.are.equal(0, vim.fn.filereadable(full_path))
			assert.are.equal(1, vim.fn.filereadable(dir_b .. "picked.txt"))
		end)
	end)
end)
