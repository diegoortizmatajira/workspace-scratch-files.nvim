local config = require("workspace-scratch-files.config")
local selector = require("workspace-scratch-files.selector")

local test_dir

describe("selector", function()
	before_each(function()
		config.current = nil
		test_dir = vim.fn.tempname() .. "/scratches/"
		vim.fn.mkdir(test_dir, "p")
		config.update({
			sources = {
				test = test_dir,
			},
			icons = {
				test = "T ",
				default = "D ",
			},
			highlight = {
				test = "Function",
				default = "Normal",
			},
		})
	end)

	after_each(function()
		local files = vim.fn.glob(test_dir .. "*", false, true)
		for _, f in ipairs(files) do
			vim.uv.fs_unlink(f)
		end
		vim.fn.delete(test_dir, "d")
	end)

	describe("select_file", function()
		it("notifies when no scratch files exist", function()
			local notifications = {}
			local original_notify = vim.notify
			vim.notify = function(msg, level)
				table.insert(notifications, { msg = msg, level = level })
			end

			selector.select_file("Test", function() end)

			vim.notify = original_notify
			assert.are.equal(1, #notifications)
			assert.is_truthy(notifications[1].msg:find("No scratch files found", 1, true))
		end)

		it("finds files in the source directory", function()
			vim.fn.writefile({}, test_dir .. "file1.txt")
			vim.fn.writefile({}, test_dir .. "file2.lua")

			-- Stub vim.ui.select to capture the items passed to it
			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_file("Test", function() end)

			vim.ui.select = original_select
			assert.is_not_nil(captured_items)
			assert.are.equal(2, #captured_items)
		end)

		it("excludes directories from file listing", function()
			vim.fn.writefile({}, test_dir .. "file.txt")
			vim.fn.mkdir(test_dir .. "subdir", "p")

			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_file("Test", function() end)

			vim.ui.select = original_select
			assert.is_not_nil(captured_items)
			assert.are.equal(1, #captured_items)
			assert.is_truthy(captured_items[1].path:find("file.txt", 1, true))

			vim.fn.delete(test_dir .. "subdir", "d")
		end)

		it("applies correct icons and highlights from config", function()
			vim.fn.writefile({}, test_dir .. "styled.txt")

			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_file("Test", function() end)

			vim.ui.select = original_select
			assert.is_not_nil(captured_items)
			assert.are.equal("T ", captured_items[1].icon)
			assert.are.equal("Function", captured_items[1].icon_hl)
			assert.are.equal("test", captured_items[1].source)
		end)

		it("uses default icon when source has no specific icon", function()
			config.update({
				sources = { other = test_dir },
			})
			vim.fn.writefile({}, test_dir .. "file.txt")

			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_file("Test", function() end)

			vim.ui.select = original_select
			assert.is_not_nil(captured_items)
			assert.are.equal("D ", captured_items[1].icon)
		end)
	end)

	describe("select_source", function()
		it("notifies when config is not initialized", function()
			config.current = nil
			local notifications = {}
			local original_notify = vim.notify
			vim.notify = function(msg, level)
				table.insert(notifications, { msg = msg, level = level })
			end

			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_source(function() end)

			vim.notify = original_notify
			vim.ui.select = original_select
			assert.is_truthy(#notifications > 0)
			assert.is_truthy(notifications[1].msg:find("Configuration not found", 1, true))
		end)

		it("lists all configured sources", function()
			config.update({
				sources = {
					alpha = "/tmp/alpha/",
					beta = "/tmp/beta/",
				},
			})

			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_source(function() end)

			vim.ui.select = original_select
			assert.is_not_nil(captured_items)

			local names = {}
			for _, item in ipairs(captured_items) do
				names[item.source] = true
			end
			assert.is_true(names["alpha"])
			assert.is_true(names["beta"])
		end)

		it("evaluates function-based source paths", function()
			config.update({
				sources = {
					dynamic = function()
						return "/tmp/dynamic-path/"
					end,
				},
			})

			local captured_items
			local original_select = vim.ui.select
			vim.ui.select = function(items, _, _)
				captured_items = items
			end

			selector.select_source(function() end)

			vim.ui.select = original_select
			assert.is_not_nil(captured_items)

			local found = false
			for _, item in ipairs(captured_items) do
				if item.source == "dynamic" then
					assert.are.equal("/tmp/dynamic-path/", item.path)
					found = true
				end
			end
			assert.is_true(found)
		end)
	end)
end)
