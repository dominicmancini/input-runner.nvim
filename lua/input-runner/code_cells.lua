local M = {}
-- local Terminal = require("toggleterm.terminal").Terminal
local toggleterm = require("toggleterm")
local utils = require("toggleterm.utils")
local repl = require("input-runner.repl")
local notif = repl.notif
-- local nn_okay, nn = pcall(require, "notebook-navigator")

---@class CurPosition
---@field line integer
---@field col integer

---@class CellPos
---@field from CurPosition
---@field to CurPosition

---@alias Direction
---| '"u"' # up (above)
---| '"d"' # down (below)

---Get the cell marker for the given buffer or filetype (current buf if neither provided)
---@param buf integer? Buffer to get cell marker of (takes precedence over ft)
---@param ft string? Filetype to get cell marker of
function M.get_cell_marker(buf, ft)
	local comment
	if not buf and not ft then
		buf = vim.api.nvim_get_current_buf()
	end
	if ft and not buf then
		comment = vim.api.nvim_get_option_value("commentstring", { filetype = ft })
	else
		comment = vim.bo[buf].commentstring
	end
	if utils.str_is_empty(comment) then
		return "# %%"
	end
	return comment:format("%%")
end

---Find the position of the current cells start and end
---@param textobj_prefix "'i'" | "'a'" The 'type' of textobj 'a' (around) / 'i' (inside)
---@param cell_marker string? the Cell marker type for filetype (eg. '# %%')
---@return CellPos
M.find_cell_pos = function(textobj_prefix, cell_marker)
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

---Check if array of lines is 'empty'.
---Returns true if tbl is empty, or if strings in table are all empty.
---Examples:
--- `lines = { 'hello', '', 'world' } -> false`
--- `lines = { "" } -> true`.
--- `lines = {} -> true`
---@param lines table
---@return boolean is_empty whether lines are spiritually 'empty'
function M.lines_empty(lines)
	if #lines > 0 then
		if #utils.tbl_filter_empty(lines) > 0 then
			return false
		end
	end
	return true
end

---Jump to the next or previous cell
---@param dir Direction Direction to move 'd' (down), 'u' (up)
---@param cell_marker? string The cell marker string
---@return string|unknown
M.move_cell = function(dir, cell_marker)
	cell_marker = cell_marker or M.get_cell_marker()
	local search_res
	local result

	if dir == "d" then
		search_res = vim.fn.search("^" .. cell_marker, "W")
		if search_res == 0 then
			result = "last"
		end
	else
		search_res = vim.fn.search("^" .. cell_marker, "bW")
		if search_res == 0 then
			result = "first"
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
		end
	end

	return result
end

---Add a cell above or below current cell.
---@param dir Direction Direction to move 'd' (down), 'u' (up)
---@param cell_marker? string Cell Marker
---@param buf? integer Buffer
M.add_cell = function(dir, cell_marker, buf)
	buf = buf or 0
	cell_marker = cell_marker or M.get_cell_marker() -- defaults to cell marker of current buf
	local cell_obj = M.find_cell_pos("a", cell_marker)
	if dir == "u" then
		-- Add cell before current cell
		vim.api.nvim_buf_set_lines(buf, cell_obj.from.line - 1, cell_obj.from.line - 1, false, { cell_marker, "" })
		M.move_cell("u", cell_marker)
	else
		-- add cell after current cell
		vim.api.nvim_buf_set_lines(buf, cell_obj.to.line, cell_obj.to.line, false, { cell_marker, "" })
		M.move_cell("d", cell_marker)
	end
end

---Filter line(s) by removing empty lines
---@param lines string[]|string
---@return string[]
local function process_lines(lines)
	if type(lines) == "string" then
		lines = { lines }
	end
	return utils.tbl_filter_empty(lines)
end

---Extract lines from the current cell
---@param buf integer? Buffer (default current buf)
---@return string[] lines Lines of text
function M.extract_cell_lines(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local marker = vim.bo[buf].commentstring or "# %s"
	marker = marker:format("%%")
	local cell_pos = M.find_cell_pos("i", marker)
	local r = require("u.range").from_lines(buf, cell_pos.from.line, cell_pos.to.line)
	if not r then
		notif({ "Range object is:", r, "Cell marker used: ", marker }, "error")
		return {}
	end
	local lines = r:lines()
	return lines
end

---~~Get cell text by using an existing cell motion (from various-textobjects)~~
---Use `extract_cell_lines` instead.
---@deprecated
function M._get_cell_text_from_motion(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local Range = require("u.range")
	local r = Range.from_motion("iN", { bufnr = buf, user_defined = true })
	if not r then
		notif({ "Motion Range is nil" }, "warn")
		return
	end
	local lines = r:lines()
	-- stripping empty whitespace/lines
	local final = process_lines(lines)
	return final
end

---Send lines to repl in given terminal
---@param lines table lines to send to terminal
---@param term Terminal a ToggleTerm object to send to
function M.send_lines(lines, term)
	if M.lines_empty(lines) then
		notif({ "'lines' are empty: ", lines }, "warn")
		return
	end
	local filtered_lines = utils.tbl_filter_empty(lines)
	term:send(filtered_lines, true)
end

function M.alternate_send_lines(lines, term)
	if M.lines_empty(lines) then
		notif({ "'lines' are empty: ", lines }, "warn")
		return
	end
	local filtered_lines = utils.tbl_filter_empty(lines)
	-- toggleterm.exec(cmd, num?, size?, dir?, direction?, name?, go_back?, open?)
	term:send(filtered_lines, true)
end

---Get the current line text (in Normal mode) or the selection (in Visual mode)
---@param mode string? The mode to get for, defaults to current mode (vim.fn.mode())
---@return string[] lines Line(s) of text (unfiltered)
function M.get_line_or_visual_text(mode)
	mode = mode or vim.fn.mode()
	local lines, r
	if string.lower(mode) == "v" then
		r = require("u.range").from_vtext()
	else
		local buf = vim.api.nvim_get_current_buf()
		local lnr = vim.fn.line(".")
		r = require("u.range").from_line(buf, lnr)
	end
	lines = r:lines() or {}
	return lines
end

---Get lines of current visual selection, and send to the term.
---@param term Terminal
function M.send_visual(term)
	local lines = M.get_line_or_visual_text("v")
	M.send_lines(lines, term)
end

---Send the cell at current cursor Position
---@param term Terminal
function M.send_cell(term)
	local lines = M.extract_cell_lines()
	-- lines = process_lines(lines) -- already done in 'send_lines'
	if lines then
		M.send_lines(lines, term)
	end
end

---Send current cell and move to next, adding new cell if at the end
---Fallsback to just sending cell if notebook-navigator not available
---@param term Terminal
function M.send_cell_then_move(term)
	M.send_cell(term)
	local state = M.move_cell("d")
	if state and state == "last" then
		M.add_cell("d")
	end
end

---Sends current line and moves to the next ('j')
---@param term Terminal
function M.send_line_and_move(term)
	local line = M.get_line_or_visual_text("n")
	M.send_lines(line, term)
	vim.cmd("normal j")
end

return M
