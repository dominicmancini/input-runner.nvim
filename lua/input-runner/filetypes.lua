local M = {}

M.python = "python -m %:.:r:gs?/?.?"
-- M.ipython = "ipython"
M.ipython = "ipython --profile=irunner -m %:.:r:gs?/?.?"
---@see lua-shell-command 'https://www.reddit.com/r/neovim/comments/1f2cyby/how_to_execute_lua_from_inside_neovim/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button'
M.lua = "nvim -l %"

local function print_stuff(t)
	vim.print(t)
end

local conf = vim.api.nvim_win_get_config(0)
print_stuff(conf)
