local config = require("workspace-scratch-files.config")

describe("config", function()
	before_each(function()
		config.current = nil
	end)

	describe("update", function()
		it("initializes current from defaults when called with no args", function()
			config.update()
			assert.is_not_nil(config.current)
			assert.is_not_nil(config.current.sources.global)
			assert.is_not_nil(config.current.sources.workspace)
		end)

		it("initializes current from defaults when called with empty table", function()
			config.update({})
			assert.are.same(config.default.icons, config.current.icons)
			assert.are.same(config.default.highlight, config.current.highlight)
		end)

		it("merges user-provided icons with defaults", function()
			config.update({ icons = { global = "G " } })
			assert.are.equal("G ", config.current.icons.global)
			assert.are.equal(config.default.icons.workspace, config.current.icons.workspace)
			assert.are.equal(config.default.icons.default, config.current.icons.default)
		end)

		it("merges user-provided highlights with defaults", function()
			config.update({ highlight = { global = "CustomHl" } })
			assert.are.equal("CustomHl", config.current.highlight.global)
			assert.are.equal(config.default.highlight.workspace, config.current.highlight.workspace)
		end)

		it("allows overriding sources with string paths", function()
			config.update({ sources = { global = "/tmp/my-scratches/" } })
			assert.are.equal("/tmp/my-scratches/", config.current.sources.global)
		end)

		it("allows overriding sources with functions", function()
			local custom_fn = function()
				return "/tmp/custom/"
			end
			config.update({ sources = { custom = custom_fn } })
			assert.are.equal(custom_fn, config.current.sources.custom)
		end)

		it("rejects non-table config", function()
			assert.has_error(function()
				config.update("invalid")
			end)
		end)

		it("rejects non-table sources", function()
			assert.has_error(function()
				config.update({ sources = "invalid" })
			end)
		end)

		it("rejects non-table icons", function()
			assert.has_error(function()
				config.update({ icons = 42 })
			end)
		end)

		it("rejects non-table highlight", function()
			assert.has_error(function()
				config.update({ highlight = true })
			end)
		end)
	end)

	describe("default sources", function()
		it("global source returns a path under stdpath('data')", function()
			config.update()
			local path = type(config.current.sources.global) == "function" and config.current.sources.global()
				or config.current.sources.global
			assert.is_truthy(path:find(vim.fn.stdpath("data"), 1, true))
			assert.is_truthy(path:match("global/$"))
		end)

		it("workspace source returns a path containing cwd folder name and hash", function()
			config.update()
			local path = type(config.current.sources.workspace) == "function" and config.current.sources.workspace()
				or config.current.sources.workspace
			local cwd_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
			assert.is_truthy(path:find(cwd_name, 1, true))
			assert.is_truthy(path:match("/$"))
		end)

		it("workspace source produces consistent paths for the same cwd", function()
			config.update()
			local fn = config.current.sources.workspace
			local path1 = fn()
			local path2 = fn()
			assert.are.equal(path1, path2)
		end)
	end)
end)
