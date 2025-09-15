local M = {}

---@alias ft string Filetype name (eg. `python`)
---@alias cmd string Pre-expansion command name (eg. `python -u %`)

---@alias ft_map table<ft, cmd> Mapping of filetypes to default commands (pre-expansion) (eg. `{ python = 'python -u %' }`)
-- ---@type table<ft, cmd> Mapping of filetypes to default commands (pre-expansion) (eg. `{ python = 'python -u %' }`)

---@type ft_map Mapping of filetypes to default commands (pre-expansion) (eg. `{ python = 'python -u %' }`)
M.run_cmds = {
	python = "python -m %:.:r:gs?/?.?",
	ipython = "ipython %",
	lua = "nvim -l %",
	sh = "bash ./%:.",
}

---@type ft_map Mapping of filetypes to default commands (pre-expansion) (eg. `{ python = 'python -u %' }`)
M.repl_cmds = {
	python = "jupyter console --kernel",
	r = "radian",
}

---@type ft_map Mapping of filetypes to default commands (pre-expansion) (eg. `{ python = 'python -u %' }`)
M.interactive_cmds = {
	python = "ipython -i %",
}

---@see lua-shell-command 'https://www.reddit.com/r/neovim/comments/1f2cyby/how_to_execute_lua_from_inside_neovim/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button'
local lua_cmd = "nvim -l %"

return M
