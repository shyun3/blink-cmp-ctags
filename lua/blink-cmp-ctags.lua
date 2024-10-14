local function get_current_word_prefix()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local col = cursor[2]
	local line = vim.api.nvim_get_current_line()
	local prefix = line:sub(1, col):match("[%w_]*$") or ""
	return prefix
end

local function tags_to_items(tags)
	local items = {}
	for _, tagname in ipairs(tags) do
		table.insert(items, {
			label = tagname,
			kind = vim.lsp.protocol.CompletionItemKind.Field,
			insertText = tagname,
		})
	end
	return items
end

local ctags = {}

function ctags.new()
	return setmetatable({}, { __index = ctags })
end

function ctags:get_completions(_, callback)
	-- Check if there are any tags files
	if #vim.fn.tagfiles() == 0 then
		callback({
			is_incomplete_forward = false,
			is_incomplete_backward = false,
			items = {},
		})
		return function() end
	end

	local prefix = get_current_word_prefix()
	local tags = vim.fn.getcompletion(prefix .. "*", "tag")
	local items = tags_to_items(tags)

	callback({
		is_incomplete_forward = false,
		is_incomplete_backward = false,
		items = items,
	})

	return function() end
end

return ctags
