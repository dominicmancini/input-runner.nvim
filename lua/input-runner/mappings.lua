local M = {}
local term = require("input-runner.term")
local input = require("input-runner.input")
local config = require("input-runner.config").get_user_config()

---Gets and runs the command for the numbered env. var specified by `i`. (eg. `$IR_CMD2`)
---@param i integer The number of the command to run (1-9). Used to get `$IR_CMD<i>`
local function numbered_cmd_run(i)
	local command_var = config.command_var
	local env_cmd = command_var .. i -- the env. var for the numbered command
	local cmd = os.getenv(env_cmd)
	if not cmd then
		vim.notify(env_cmd .. " environment variable not set", vim.log.levels.ERROR)
		return
	end
	local expanded_cmd = input.prepare_and_remember_cmd(cmd)
	if not expanded_cmd or expanded_cmd == "" then
		vim.notify("Command for " .. env_cmd .. " is empty", vim.log.levels.ERROR)
		return
	end
	term.ProjectTerm(expanded_cmd)
end

---Creates the <plug> mappings for running default and numbered IR commands.
function M.setup()
	-- Create a mapping for setting the command variable
	vim.api.nvim_set_keymap("n", "<Plug>(IRSetCmd)", ":IRSetCmd<CR>", { noremap = true, silent = true })
	-- Create a mapping for running the command
	vim.api.nvim_set_keymap("n", "<Plug>(IRRun)", ":IRRun<CR>", { noremap = true, silent = true })
	-- Create numbered mappings for running commands from numbered variables
	for i = 1, 9 do
		local lhs = string.format("<Plug>(IRRun%d)", i)
		vim.keymap.set("n", lhs, function()
			numbered_cmd_run(i)
		end, { noremap = true, silent = true, desc = "Run command from " .. string.format("$IR_CMD%d", i) })
	end
end

return M
