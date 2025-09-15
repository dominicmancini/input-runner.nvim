local hydra_ok, Hydra = pcall(require, "hydra")
local nn_ok, nn = pcall(require, "notebook-navigator")
local code = require("input-runner.code")

local function determine_provider()
	-- vim.g.ir_term_info = nil
	-- vim.g.ir_repl_active = false
	local provider
	if require("molten.status").initialized() ~= "" then
		provider = "molten"
	else
		provider = "toggleterm"
	end
	return provider
end

-- local ok, cmt = pcall(require, "notebook-navigator.utils")
-- TODO: Refactor with logic to account for if nn & hydra not available

--- Possible Vim-Regex to match cells in most languages:
--- starts non-word character 1 or more
--- ^\W\+ %%$
--- ^\W\{1,2} %%$
--- ^[^0-9A-Za-z_\s]\+ %%$ (might be better, cuz no whitespace)
--- For capturing the line line before a new cell:
--- \v(.*)\n\@=-- \%\%$
local cell_pat = "^[^0-9A-Za-z_\\s]\\+ %%$"

--- Jump to a cell and control with flags
--- Some useful flags:
---   next cell start (wrapping) = "wz"
---   start of current cell = "bcW"
---   next cell (no-wrap, first) = "cW"
---@param flags string flags passed to `vim.fn.search`
local function go_to(flags)
	flags = flags or "wz"
	-- vim.fn.search("^[^0-9A-Za-z_\\s]\\+ %%$", flags)
	vim.fn.search(cell_pat, flags)
end

---@param buf? integer
local function get_marker(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	return (vim.bo[buf].commentstring):format("%%")
end

---Merge two cells above and below (deletes delimiting # %%)
---@param buf integer?
local function merge_cells(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local marker = get_marker(buf)
	local curline = vim.fn.line(".")
	local match = vim.regex("\\V" .. marker):match_line(buf, curline - 1)
	if match then
		local res = vim.fn.deletebufline(buf, curline)
		if res ~= 0 then
			vim.fn.setline(curline, "")
		end
	end
end

---Jump to the last (non-whitespace) line in the cell. Should start insert/append after calling this function
---@param buf integer? Buffer number (defaults to current buf)
---@return integer line The line number jumped to
local function goto_last_cell_line(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local cmt = vim.bo.commentstring or "# %s"
	local cmt_pat = cmt:format(""):gsub("%s", "")
	-- First, go to start of next cell
	local pos = nn.move_cell("d")
	local flags = "bWze"
	if pos and pos == "last" then
		flags = "Wze" -- Remove backwards search
	end
	local line = vim.fn.search("^[^\n" .. cmt_pat .. "]", flags)
	return line
end

local heads = {
	{
		"j",
		function()
			nn.move_cell("d")
		end,
		{ desc = "Move down" },
	},
	{
		"k",
		function()
			nn.move_cell("u")
		end,
		{ desc = "Move up" },
	},
	{
		"a",
		function()
			nn.add_cell_above()
		end,
		{ desc = "Add cell above" },
	},
	{
		"b",
		function()
			nn.add_cell_below()
		end,
		{ desc = "Add cell below" },
	},
	{
		-- TODO: Have 'enter' trigger a 'hop'/'easymotion' that jumps to character in the cell
		"<CR>",
		function()
			goto_last_cell_line()
			vim.cmd("startinsert!") -- '!' means to append instead of insert
		end,
		{ desc = "Edit cell", exit = true },
	},
	{
		"<S-CR>",
		function()
			nn.run_cell()
			-- vim.print("Run Cell (stay)!")
		end,
		{ desc = "Run cell" },
	},
	{
		"<C-CR>",
		function()
			nn.run_and_move()
			-- vim.print("Execute Cell!")
			-- nn.move_cell("d")
		end,
		{ desc = "Run cell & down" },
	},
	{
		"c",
		function()
			nn.comment_cell()
		end,
		{ desc = "Comment cell" },
	},
	{
		"J",
		function()
			nn.swap_cell("d")
		end,
		{ desc = "Swap cell down" },
	},
	{
		"K",
		function()
			nn.swap_cell("u")
		end,
		{ desc = "Swap cell up" },
	},
	{
		"m",
		function()
			merge_cells()
		end,
		{ desc = "Merge cells" },
	},
	{ "q", nil, { exit = true, nowait = true, desc = "exit" } },
	{ "<Esc>", nil, { exit = true, nowait = true, desc = "exit" } },
}

local hint = [[
_j_/_k_: Move down/up   _a_/_b_: Add after/before   _J_/_K_: Swap down/up
         _c_: Comment cell toggle        _m_: Merge Cells
^
        _<C-CR>_: Run cell & move       _<S-CR>_: Run cell
^        _<CR>_: Edit cell              _<Esc>_/_q_: exit
]]

local o = {
	name = "Notebook Mode",
	mode = "n",
	-- body = "<leader>z", -- Disable body, let user assign it
	---@diagnostic disable-next-line: assign-type-mismatch
	hint = hint,

	config = {
		exit = false, -- default exit value for the heads
		foreign_keys = "warn",
		color = "red",
		invoke_on_body = true, -- Start on '<leader>z'
		hint = {
			---@type vim.api.keyset.win_config
			float_opts = {
				border = "rounded",
			},
			type = "window",
		},
		on_enter = function()
			local provider = determine_provider()
			nn.config.repl_provider = provider
			go_to("bcW") -- Jump to start of current cell on start
		end,
	},
	heads = heads,
}

local hydra = Hydra(o)

return {
	hydra = hydra,
}
