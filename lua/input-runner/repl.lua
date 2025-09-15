local M = {}

local Terminal = require("toggleterm.terminal").Terminal
local toggleterm = require("toggleterm")
local utils = require("toggleterm.utils")
local sm = require("stackmap")

---@param msg table|any Any message, objects, etc to notify.
---@param err string? Log Level (eg. 'warn'), if nil then 'INFO'.
local notif = function(msg, err)
	local msg_txt = vim.inspect(msg)
	local lvl = err and vim.log.levels[err:upper()] or vim.log.levels.INFO
	vim.schedule(function()
		vim.notify(msg_txt, lvl, { title = "Input-Runner" })
	end)
end

local split_height = function()
	local lines = vim.api.nvim_get_option_value("lines", {})
	return math.floor(lines * 0.4)
end

local vsplit_height = function()
	local columns = vim.api.nvim_get_option_value("columns", {})
	return math.floor(columns * 0.4)
end

---@param cmd string
local function get_repl_cmd_name(cmd)
	local cmd_pos = { cmd:find("^(%w*)") }
	local cmd_name = cmd_pos[3] or ""
	local kernel_pos = { cmd:find("--kernel=?(%w+)") }
	local kernel_name = kernel_pos[3] or ""
	local repl_name = utils.concat_without_empty({ "IR Repl", cmd_name, kernel_name }, " : ")
	return repl_name
end
local function toggle_var(name)
	vim.g[name] = not vim.g[name]
end

---Map Convenience
---@param buf integer|nil
---@param lhs string
---@param rhs string|function
---@param desc string?
---@param mode string|string[]?
local function map(buf, lhs, rhs, desc, mode)
	mode = mode or "n"
	if buf ~= nil then
		-- if buffer is provided, we are being set in a FileType autocmd
		vim.keymap.set(mode, lhs, rhs, { desc = desc, buffer = buf, noremap = true })
	else
		-- If buf is nil, we are setting a  global keymap
		vim.keymap.set(mode, lhs, rhs, { desc = desc, noremap = true })
	end
end

---Get the Cell Marker for a given buffer
---@param buf integer|nil
local function get_cell_marker(buf)
	if buf == nil then
		return nil
	end
	local cmt_string = vim.bo[buf].commentstring
	if cmt_string == "" then
		return nil
	end
	return cmt_string:format("%%")
end

---Set keymaps for REPL
---@param term Terminal
---@param buf integer|nil
local function set_keymaps(term, buf)
	local cell_marker = get_cell_marker(buf)
	-- local code = require("input-runner.code_cells")
	-- TODO: Mess with 'code_cells' module to
	-- speed up sending of lines
	-- map(buf, "<leader>z", function()
	-- 	code.send_cell(term)
	-- end, "OLD send cell", "n")
	-- map(buf, "<C-CR>", function()
	-- 	code.send_cell_then_move(term)
	-- end, "Send Cell")
	-- map(buf, "<CR>", function()
	-- 	code.send_line_and_move(term)
	-- end, "send line and move down", "n")
	-- map(buf, "<CR>", function()
	-- 	code.send_visual(term)
	-- end, "send visual selection", "v")
	local code = require("input-runner.code")
	map(buf, "<CR>", function()
		code.send_lines_to_term("single_line", term)
	end, "send line", "n")
	map(buf, "<CR>", function()
		code.send_lines_to_term("visual_lines", term)
	end, "send visual lines", "v")
	map(buf, "<C-CR>", function()
		code.send_cell_to_term(term, cell_marker)
	end, "send cell", "n")
end

local function tear_down_autocmd()
	local autocmds = vim.api.nvim_get_autocmds({
		group = "IRReplKeymaps",
		event = "FileType",
	})
	if #autocmds > 0 then
		vim.api.nvim_del_augroup_by_name("IRReplKeymaps")
	end
	return
	-- if #autocmds > 0 then
	-- 	for _, autocmd in ipairs(autocmds) do
	-- 		-- vim.api.nvim_del_augroup_by_name
	-- 	end
	-- end
end

---@type TermCreateArgs
local default_term_opts = {
	close_on_exit = true,
	hidden = false,

	-- display_name = "IR Repl" -- Set display name when cmd available
	direction = "vertical", -- vertical by default
	-- keep close on exit, so term will close with process

	auto_scroll = true,
	on_create = function(term)
		vim.g.ir_term_info = term
		-- set_keymaps(term)
	end,
	on_exit = function(t, job, exit_code, name)
		vim.g.ir_term_info = nil
		vim.g.ir_repl_active = false
		tear_down_autocmd()
	end,
	on_open = function(term)
		vim.cmd("wincmd p")
		vim.g.ir_repl_active = true
		vim.keymap.set("n", "q", function()
			if term:is_open() then
				term:close()
			end
			term:shutdown()
		end, { buffer = term.bufnr, noremap = true, silent = true, desc = "Exit term process and close window" })
	end,
	on_close = function(term)
		-- NOTE: Now, when closing the window -  it will automatically stop the process (send 'SIGTERM' <C-c> first, then 'SIGKILL' if still neede)
		local chan = vim.bo[term.bufnr].channel
		-- NOTE: This will cause the 'on_exit' callback to be invoked
		vim.fn.jobstop(chan)
	end,
}

---Setup the REPL keymaps. The filetype from which `Repl_term` was invoked is used for the
---'FileType' autocmd pattern. If called from buffer with no filetype, the keymaps are set
---globally.
---
---eg. starting from 'main.py' will create autocmd to set keymaps for all python filetypes.
---if invoked from startup buffer, will be set globally.
---@param buf any
---@param term any
local function setup_keymaps(buf, term)
	local okay, ft = pcall(vim.api.nvim_get_option_value, "filetype", { buf = buf })
	local use_autocmd
	if okay then
		if ft and ft ~= "" then
			use_autocmd = true
		end
	else
		use_autocmd = false
	end
	if use_autocmd then
		-- Set kemaps for original buffer first
		set_keymaps(term, buf)
		-- Then set keymaps through autocmd for other bufs of this filetype
		vim.api.nvim_create_autocmd("FileType", {
			pattern = ft,
			group = vim.api.nvim_create_augroup("IRReplKeymaps", { clear = true }),
			callback = function(args)
				set_keymaps(term, args.buf)
			end,
		})
	else
		set_keymaps(term, nil)
	end
end

---Launch the IR Repl with `cmd` and any additional term options to merge with the ToggleTerm default opts
---@param cmd string The command to start Repl (eg. 'jupyter console --kernel=python3')
---@param extra_opts TermCreateArgs? Additional args for `Terminal:new({..})`
local function Repl_Term(cmd, extra_opts)
	extra_opts = extra_opts or {}
	local final_term_opts = vim.tbl_deep_extend("force", default_term_opts, extra_opts)
	if not cmd or cmd == "" then
		notif({ "[IR] 'cmd' is not valid (nil or '')" }, "error")
		return
	end
	final_term_opts["cmd"] = cmd
	final_term_opts["display_name"] = get_repl_cmd_name(cmd)
	local buf = vim.api.nvim_get_current_buf() -- Get the current, non-terminal buffer (for keymaps)
	local term = Terminal:new(final_term_opts)
	term:toggle()
	setup_keymaps(buf, term)
end

return {
	Repl_term = Repl_Term,
	notif = notif,
	toggle_g_var = toggle_var,
}
