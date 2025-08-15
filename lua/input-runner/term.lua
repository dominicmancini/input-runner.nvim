local M = {}

local Terminal = require("toggleterm.terminal").Terminal

local calculate_height = function()
	local lines = vim.api.nvim_get_option_value("lines", {})
	return math.floor(lines * 0.8)
end

local calculate_width = function()
	local columns = vim.api.nvim_get_option_value("columns", {})
	return math.floor(columns * 0.7)
end
---@module 'toggleterm'
---@type TermCreateArgs
local default_term_opts = {
	display_name = "Input-Runner",
	direction = "float",
	close_on_exit = false,
	---@type vim.api.keyset.win_config
	float_opts = {
		border = "rounded",
		height = calculate_height(),
		width = calculate_width(),
		title_pos = "center",
	},
	highlights = {
		FloatBorder = {
			guifg = "#c586c0",
			-- OTHER OPTIONS:
			-- guifg = "#9cdcfe",
			-- guifg = "#4ec9b0",
			guibg = "#1e1e1e", -- Background color for the terminal
		},
	},
	on_open = function(term)
		vim.keymap.set("n", "q", function()
			term:shutdown()
		end, { buffer = term.bufnr, noremap = true, silent = true, desc = "Exit term process and close window" })
	end,
	on_close = function(term)
		-- NOTE: Now, when closing the window -  it will automatically stop the process (send 'SIGTERM' <C-c> first, then 'SIGKILL' if still neede)
		--
		local chan = vim.bo[term.bufnr].channel
		vim.fn.jobstop(chan)
	end,
}

---Launch the project terminal with `cmd` and any additional term options to merge with the ToggleTerm default opts
---@param cmd string the cmd to run (takes precedence over cmd in `extra_opts`)
---@param extra_opts TermCreateArgs? Additional args for `Terminal:new({..})`
function M.ProjectTerm(cmd, extra_opts)
	-- Open floating terminal executing command defined by environment variable
	extra_opts = extra_opts or {}
	local final_term_opts = vim.tbl_deep_extend("force", default_term_opts, extra_opts)
	if cmd ~= nil and cmd ~= "" then
		final_term_opts["cmd"] = cmd
	end
	local term = Terminal:new(final_term_opts)

	term:toggle()
end

return M
