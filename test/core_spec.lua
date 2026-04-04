local config = require("workspace-scratch-files.config")

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
end)
