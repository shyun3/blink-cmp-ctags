local uv = vim.loop
local api = vim.api
local async = require("blink.cmp.lib.async")
local lsp = vim.lsp.protocol
local debug = false

local ctags = {}

-- Default configuration
local default_config = {
	tag_files = vim.fn.tagfiles(), -- List of tag files
	cache = true,
	include_kinds = { "f", "v", "c", "m", "t" }, -- Tag kinds to include
	max_items = 500, -- Maximum number of completion items to return
}

-- Mapping of tag kinds to LSP completion kinds
local tag_kinds_map = {
	f = lsp.CompletionItemKind.Function,
	v = lsp.CompletionItemKind.Variable,
	c = lsp.CompletionItemKind.Class,
	m = lsp.CompletionItemKind.Method,
	t = lsp.CompletionItemKind.Struct,
}

-- Debugging Utility
local function debug_print(msg)
	if debug then
		print("[Ctags Plugin] " .. msg)
	end
end

-- Merge documentation from new_item into existing_item
local function merge_documentation(existing_item, new_item)
	existing_item.documentation.value = existing_item.documentation.value .. "  \n" .. new_item.documentation.value
end

-- Helper function to generate markdown documentation
local function generate_documentation(file, tag)
	local tag_doc = string.format("*Tag:* `%s`  \n", tag)
	local file_doc = string.format("*From:* `%s`  \n", file)
	return tag_doc .. file_doc
end

-- Initialize a new ctags instance
function ctags.new(user_config)
	local self = setmetatable({}, { __index = ctags })
	self.config = vim.tbl_extend("force", default_config, user_config or {})
	self.cached_items = {} -- { ['.rb'] = { ['name'] = item, ... }, ... }
	self.loading = true
	self:_load_tags_async()
	return self
end

-- Asynchronously load all tag files
function ctags:_load_tags_async()
	debug_print(string.format("Preparing to load %d tags files", vim.tbl_count(self.config.tag_files)))

	local tasks = vim.tbl_map(function(tagfile)
		return self:_load_tagfile_async(tagfile)
	end, self.config.tag_files)

	async.task
		.all(tasks)
		:map(function(results)
			for _, res in ipairs(results) do
				for ext, items_map in pairs(res) do
					self.cached_items[ext] = self.cached_items[ext] or {}
					for label, item in pairs(items_map) do
						if self.cached_items[ext][label] then
							merge_documentation(self.cached_items[ext][label], item)
						else
							self.cached_items[ext][label] = item
						end
					end
					debug_print(
						string.format("Loaded %d unique items for extension '%s'", vim.tbl_count(items_map), ext)
					)
				end
			end
			self.loading = false
			debug_print("Finished loading all tags. Total extensions cached: " .. vim.tbl_count(self.cached_items))
		end)
		:catch(function(err)
			self.loading = false
			debug_print("Error loading tags: " .. tostring(err))
		end)
end

-- Asynchronously load a single tag file
function ctags:_load_tagfile_async(tagfile)
	return async.task.new(function(resolve, reject)
		debug_print("Loading tagfile: " .. tagfile)

		uv.fs_open(tagfile, "r", 438, function(err_open, fd)
			if err_open then
				return reject("Cannot open file: " .. tagfile .. " Error: " .. err_open)
			end

			uv.fs_fstat(fd, function(err_stat, stat)
				if err_stat then
					uv.fs_close(fd)
					return reject("Cannot stat file: " .. tagfile .. " Error: " .. err_stat)
				end

				if stat.size == 0 then
					uv.fs_close(fd)
					debug_print("Empty tagfile: " .. tagfile)
					return resolve({})
				end

				uv.fs_read(fd, stat.size, 0, function(err_read, data)
					uv.fs_close(fd)
					if err_read then
						return reject("Error reading file: " .. tagfile .. " Error: " .. err_read)
					end

					local lines = vim.split(data, "\n")
					local items = {}
					local seen = {}

					for _, line in ipairs(lines) do
						local item = self:_parse_line(line)
						if item then
							local ext = self:_get_file_extension(item.file)
							if ext then
								items[ext] = items[ext] or {}
								seen[ext] = seen[ext] or {}
								if not seen[ext][item.label] then
									seen[ext][item.label] = true
									items[ext][item.label] = item
								else
									merge_documentation(items[ext][item.label], item)
								end
							else
								debug_print("Unknown extension for file: " .. item.file)
							end
						end
					end

					debug_print(
						"Completed reading tagfile: "
							.. tagfile
							.. " Total unique items found: "
							.. tostring(vim.tbl_count(items))
					)
					resolve(items)
				end)
			end)
		end)
	end)
end

-- Get the file extension from a file path
function ctags:_get_file_extension(filepath)
	local extension = filepath:match("^.+(%.[%a%d]+)$")
	if not extension then
		debug_print("Could not extract extension from path: " .. filepath)
		return nil
	end
	return extension:lower()
end

-- Parse a single line from the tag file into a completion item
function ctags:_parse_line(line)
	if not line or line == "" or line:match("^!") then
		return nil
	end

	local fields = vim.split(line, "\t", true)
	if #fields < 4 then
		debug_print("Skipping malformed line (less than 4 fields): " .. line)
		return nil
	end

	local name, file, tag, kind = fields[1], fields[2], fields[3], fields[4]

	if not vim.tbl_contains(self.config.include_kinds, kind) then
		return nil
	end

	local lsp_kind = tag_kinds_map[kind] or lsp.CompletionItemKind.Text

	return {
		label = name,
		kind = lsp_kind,
		insertText = name,
		documentation = {
			kind = "markdown",
			value = generate_documentation(file, tag),
		},
		detail = string.format("[%s] %s", kind, file),
		source = "Ctags",
		file = file,
	}
end

-- Get completions based on the current word prefix and cached items
function ctags:get_completions(context, callback)
	if self.loading then
		debug_print("Cache is still loading. Returning empty completions.")
		callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
		return function() end
	end

	local buffer_name = api.nvim_buf_get_name(0)
	local ft_extension = self:_get_file_extension(buffer_name)
	if not ft_extension then
		debug_print("Current buffer has no valid extension. Returning empty completions.")
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
		return function() end
	end

	local prefix = context.line:sub(context.bounds.start_col, context.bounds.end_col)

	if prefix == "" then
		debug_print("Empty prefix. Returning no completions.")
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
		return function() end
	end

	debug_print(string.format("Getting completions for prefix: '%s' in extension '%s'", prefix, ft_extension))

	local items_map = self.cached_items[ft_extension] or {}
	local matched_items = {}
	local seen = {}

	local success, regex = pcall(function()
		return vim.regex("^" .. vim.pesc(prefix))
	end)

	if not success then
		debug_print("Failed to create regex for prefix: '" .. prefix .. "'")
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
		return function() end
	end

	for _, item in pairs(items_map) do
		if regex:match_str(item.label) then
			if not seen[item.label] then
				table.insert(matched_items, item)
				seen[item.label] = true
			end
			if #matched_items >= self.config.max_items then
				debug_print("Reached max_items limit while filtering completions.")
				break
			end
		end
	end

	debug_print(string.format("Completions found: %d/%d", #matched_items, vim.tbl_count(items_map)))

	callback({
		is_incomplete_forward = false,
		is_incomplete_backward = false,
		items = matched_items,
	})

	return function() end
end

return ctags
