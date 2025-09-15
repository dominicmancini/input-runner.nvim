local M = {}

-- local tt = require("toggleterm")
-- local utils = require("toggleterm.utils")
local terminal = require("toggleterm.terminal")
local Terminal = terminal.Terminal
local stackmap = require("stackmap")
-- local cells = require("input-runner.code_cells")
local code = require("input-runner.code")
local notif = require("input-runner.repl").notif
local irtils = require("input-runner.utils")

local fn = vim.fn

---Send line(s) to terminal `term`
---@param term Terminal
---@param selection_type SelectionType
local function send(term, selection_type)
	local lines = code.get_lines_from_selection(selection_type)
	if not lines then
		return
	end
	term:send(lines, true)
end

---Get a new interactive buffer.
---@return integer bufid
local function get_new_buf()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "nofile"
	vim.api.nvim_buf_set_name(buf, "IR Interactive")
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<cr>", { desc = "Close", noremap = true })
	-- vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "# %%" })
	return buf
end

--- Open the interactive buf and get the win
---@param buf integer inter. buf
---@return integer window-id
local function open_win_term(buf)
	local win = vim.api.nvim_get_current_win()
	local split_win = vim.api.nvim_open_win(buf, false, { split = "right", win = win })
	local chan = vim.api.nvim_open_term(buf, {})
	return chan
end

local function stream_to_buf(buf, lines)
	if lines and #lines > 0 then
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
	end
end

---comment
---@param term Terminal
---@param curwin integer? Current window
---@param direction string?
---@param ft string? Filetype? (default python)
function M.launch_interactive_buf(term, curwin, direction, ft)
	curwin = curwin or vim.api.nvim_get_current_win()
	direction = direction or "below"
	ft = ft or "python"
	-- local cur_buf = vim.api.nvim_get_current_buf()
	local buf = get_new_buf()
	local win = vim.api.nvim_open_win(buf, true, { split = direction, win = curwin })
	vim.bo[buf].filetype = ft
	vim.keymap.set("n", "<CR>", function()
		send(term, "single_line")
	end, { buffer = buf, desc = "Send line" })
	vim.keymap.set("n", "<C-CR>", function()
		send(term, "cell")
	end, { buffer = buf, desc = "Send Cell" })
	vim.keymap.set("v", "<CR>", function()
		send(term, "visual_lines")
	end, { buffer = buf, desc = "Send Visual Line(s)" })
	return buf
end

-- local buf = get_new_buf()
-- local win
-- local og_win = vim.api.nvim_get_current_win()
-- local pos = vim.api.nvim_win_get_position(og_win)

---@type TermCreateArgs
local interactive_opts = {
	direction = "vertical",
	auto_scroll = true,
	close_on_exit = true,
	-- hidden = false,
	display_name = "IR Interactive",
	on_create = function(term)
		vim.g.ir_term_info = term
		stackmap.push("ir_normal", "n", {
			["<leader>z"] = function()
				send(term, "single_line")
			end,
			["<leader>Z"] = function()
				send(term, "cell")
			end,
		})
		stackmap.push("ir_visual", "v", {
			["<leader>z"] = function()
				send(term, "visual_lines")
			end,
		})
		-- launch_interactive_buf(term, "below")
	end,
	on_open = function(term)
		vim.keymap.set("n", "q", function()
			term:shutdown()
			-- vim.fn.jobstop(term.job_id)
		end, { buffer = term.bufnr, desc = "Close Term" })
		-- vim.cmd("wincmd h")
	end,
	on_close = function(term)
		notif("On exit callback", "info")
	end,
	on_exit = function(t, job, exit_code, name)
		vim.schedule(function()
			notif({ "Job Exited:", job, exit_code, name })
		end)
		vim.g.ir_term_info = nil
	end,
}

---Launch the interactive terminal
---@param cmd string The command to run file interactively.
---@param extra_opts TermCreateArgs? Additional Args for `Terminal:new(..)`
---@param ft string? Filetype (default. python)
---@param use_scratch_buf boolean? Open a split buf for sending code?
function M.Interactive_Term(cmd, extra_opts, ft, use_scratch_buf)
	if irtils.nil_or_empty(cmd) then
		notif("Command is Invalid", "ERROR")
		return
	end
	extra_opts = extra_opts or {}
	local final_opts = vim.tbl_deep_extend("force", interactive_opts, extra_opts)
	use_scratch_buf = use_scratch_buf ~= nil and use_scratch_buf
	final_opts.cmd = cmd
	local cur_win = vim.api.nvim_get_current_win()
	-- TODO: Handle `use_term_buf`
	local t = Terminal:new(final_opts)
	t:toggle()
	if use_scratch_buf then
		local direction = t.direction == "horizontal" and "right" or "below"
		local int_buf = M.launch_interactive_buf(t, cur_win, direction, ft)
		-- require("input-runner.comp").setup_interactive_buf(int_buf, t, ft)
	end
	return t
end

-- FOR CMD, SEE https://stackoverflow.com/questions/17815187/how-to-parse-flags-to-a-python-executable
-- local cmd = "python -i scrip.py"

return M
