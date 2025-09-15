-- %%
local cmt = require("Comment.utils")
-- local ts = require("ts_context_commentstring")
local utils = require("toggleterm.utils")
local tt = require("toggleterm")
local api = vim.api

-- %%

local function get_cell_marker(buf)
	buf = buf or api.nvim_get_current_buf()
	local cmtstring = vim.bo[buf].commentstring or "# %s"
	return cmtstring:format("%%")
end
-- %%

---@return CellPos
local find_cell_pos = function(textobj_prefix, cell_marker)
	local start_line = vim.fn.search("^" .. cell_marker, "bcnW")

	-- Just in case the notebook is malformed and doesnt  have a cell marker at the start.
	if start_line == 0 then
		start_line = 1
	else
		if textobj_prefix == "i" then
			start_line = start_line + 1
		end
	end

	local end_line = vim.fn.search("^" .. cell_marker, "nW") - 1
	if end_line == -1 then
		end_line = vim.fn.line("$")
	end

	local last_col = math.max(vim.fn.getline(end_line):len(), 1)

	local from = { line = start_line, col = 1 }
	local to = { line = end_line, col = last_col }
	return { from = from, to = to }
end

---@param pos CellPos
local function get_cell_lines(pos)
	local lines = vim.api.nvim_buf_get_lines(0, pos.from.line - 1, pos.to.line, false)
	return lines
	-- if lines and next(lines) then
	-- 	lines = utils.tbl_filter_empty(lines)
	-- 	return lines
	-- else
	-- 	return
	-- end
end

---Get and send currrent cell to terminal
---@param term Terminal? Terminal to send to (or id 1)
---@param cell_marker string?
local function send_cell_to_term(term, cell_marker, trim_spaces)
	trim_spaces = trim_spaces == nil or trim_spaces
	cell_marker = cell_marker or get_cell_marker()
	local current_win = vim.api.nvim_get_current_win()
	local id = (term and term.id ~= nil) and term.id or 1
	local pos = find_cell_pos("i", cell_marker)
	local lines = vim.api.nvim_buf_get_lines(0, pos.from.line - 1, pos.to.line, false)
	if not lines or not next(lines) then
		return
	end
	for _, line in ipairs(lines) do
		if line ~= "" then
			local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
			require("toggleterm").exec(l, id)
		end
	end
	-- lines = utils.tbl_filter_empty(lines)
	-- local clean_lines = {}
	-- for _, line in ipairs(lines) do
	-- 	table.insert(clean_lines, vim.trim(line))
	-- end
	-- local lines_str = table.concat(clean_lines, "\n")
	-- tt.exec(lines_str)

	-- Jump back with the cursor where we were at the beginning of the selection
	local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_set_current_win(current_win)

	vim.api.nvim_win_set_cursor(current_win, { cursor_line, cursor_col })
	-- if term and term.id ~= nil then
	-- 	term:send(lines_str, true)
	-- else
	-- 	tt.exec(lines_str, nil, nil, nil, nil, nil, true)
	-- end
end

local function get_line()
	local line = vim.api.nvim_get_current_line()
	return line
end

local function get_visual_selection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
	else
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
	end
	return lines
	-- return table.concat(lines, '\n')
end

---@alias SelectionType
---| 'single_line' # Single line ('n')
---| 'visual_lines' # Visual Line Selection ('V')
---| 'visual_selection' # Visual selection mode ('v')
---| 'cell' # Cell Mode `# %%`

---Execute lines
---@param lines any string or array of strings to execute
---@param term Terminal?
---@param opts table?
local function exec_lines(lines, term, opts)
	local opts = opts or {}
	local id = term and term.id or 1
	local trim_spaces = opts.trim_spaces == nil or opts.trim_spaces

	local current_window = api.nvim_get_current_win() -- save current window
	-- Don't execute with 'go_back = true', will jump back manually

	-- lines = type(lines) == "string" and { lines } or lines
	lines = utils.tbl_filter_empty(lines)
	if #lines == 0 then
		print("log[15]: code.lua:141 (after if #lines == 0 then)")
		return
	end
	vim.print(lines)
	if not trim_spaces then
		-- tt.exec(table.concat(lines, "\n"), term.id)
	else
		for _, line in ipairs(lines) do
			local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
			-- tt.exec(l, term.id)
		end
	end
	-- Jump back with the cursor where we were at the beginning of the selection
	api.nvim_set_current_win(current_window)
	-- nvim_win_set_cursor() uses 0-based indexing for columns, while we use 1-based indexing
	-- api.nvim_win_set_cursor(current_window, { start_line, start_col - 1 })
end

--- @param selection_type SelectionType Type of mode
--- @param term Terminal?
--- @param trim_spaces boolean? Trim spaces in selection
local function send_lines_to_term(selection_type, term, trim_spaces)
	local id = (term and term.id ~= nil) and term.id or 1
	trim_spaces = trim_spaces == nil or trim_spaces
	vim.validate({
		selection_type = { selection_type, "string", true },
		trim_spaces = { trim_spaces, "boolean", true },
	})

	local current_window = api.nvim_get_current_win() -- save current window

	local lines = {}
	-- Beginning of the selection: line number, column number
	local start_line, start_col
	if selection_type == "single_line" then
		start_line, start_col = unpack(api.nvim_win_get_cursor(0))
		-- nvim_win_get_cursor uses 0-based indexing for columns, while we use 1-based indexing
		start_col = start_col + 1
		table.insert(lines, vim.fn.getline(start_line))
		-- NOTE: ONLY CHANGES WERE THE FOLLOWING 'elseif' block
		-- IF NOT WORKING, just comment following block:
	elseif selection_type == "cell" then
		local marker = get_cell_marker()
		local pos = find_cell_pos("i", marker)
		lines = vim.api.nvim_buf_get_lines(0, pos.from.line - 1, pos.to.line, false)
	else
		local res = nil
		if string.match(selection_type, "visual") then
			-- This calls vim.fn.getpos, which uses 1-based indexing for columns
			res = utils.get_line_selection("visual")
		else
			-- This calls vim.fn.getpos, which uses 1-based indexing for columns
			res = utils.get_line_selection("motion")
		end
		start_line, start_col = unpack(res.start_pos)
		-- char, line and block are used for motion/operatorfunc. 'block' is ignored
		if selection_type == "visual_lines" or selection_type == "line" then
			lines = res.selected_lines
		elseif selection_type == "visual_selection" or selection_type == "char" then
			lines = utils.get_visual_selection(res, true)
		end
	end

	if not lines or not next(lines) then
		return
	end
	-- return lines
	lines = utils.tbl_filter_empty(lines)

	if not trim_spaces then
		tt.exec(table.concat(lines, "\n"), id)
	else
		for _, line in ipairs(lines) do
			local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
			tt.exec(l, id)
		end
	end

	-- Jump back with the cursor where we were at the beginning of the selection
	api.nvim_set_current_win(current_window)
	-- nvim_win_set_cursor() uses 0-based indexing for columns, while we use 1-based indexing
	api.nvim_win_set_cursor(current_window, { start_line, start_col - 1 })
end

--- Same as 'send_lines_to_term' but just extracts & returns the lines instead of executing them.
---@param selection_type SelectionType type of selection
---@param trim_spaces boolean? Trim spaces in lines (default true)
---@return string[]? lines list of lines
local function get_lines_from_selection(selection_type, trim_spaces)
	trim_spaces = trim_spaces == nil or trim_spaces
	local lines = {}
	local start_line, start_col
	if selection_type == "single_line" then
		start_line, start_col = unpack(api.nvim_win_get_cursor(0))
		-- nvim_win_get_cursor uses 0-based indexing for columns, while we use 1-based indexing
		start_col = start_col + 1
		table.insert(lines, vim.fn.getline(start_line))
	elseif selection_type == "cell" then
		local marker = get_cell_marker()
		local pos = find_cell_pos("i", marker)
		lines = vim.api.nvim_buf_get_lines(0, pos.from.line - 1, pos.to.line, false)
	else
		local res = nil
		if string.match(selection_type, "visual") then
			-- This calls vim.fn.getpos, which uses 1-based indexing for columns
			res = utils.get_line_selection("visual")
		else
			-- This calls vim.fn.getpos, which uses 1-based indexing for columns
			res = utils.get_line_selection("motion")
		end
		start_line, start_col = unpack(res.start_pos)
		-- char, line and block are used for motion/operatorfunc. 'block' is ignored
		if selection_type == "visual_lines" or selection_type == "line" then
			lines = res.selected_lines
		elseif selection_type == "visual_selection" or selection_type == "char" then
			lines = utils.get_visual_selection(res, true)
		end
	end
	if not lines or not next(lines) then
		return
	end
	local clean_lines = {}
	for _, line in ipairs(lines) do
		-- we loop to remove blanks and trim spaces (if desired)
		if line ~= "" then
			local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
			table.insert(clean_lines, l)
		end
	end
	return clean_lines
end

return {
	send_lines_to_term = send_lines_to_term,
	send_cell_to_term = send_cell_to_term,
	get_lines_from_selection = get_lines_from_selection,
}
