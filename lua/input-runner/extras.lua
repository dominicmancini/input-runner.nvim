local M = {}

local term = require("input-runner.term")

---Input a command (with snacks.input) to run and execute with input-runner.
function M.snacks_input_run()
	local input = require("snacks").input
	local cmd
	input.input({
		default = "",
		prompt = "Run command: ",
	}, function(value)
		cmd = value
		if cmd == "" then
			vim.print("No command provided.")
			return
		end

		-- run command directly without setting env var
		cmd = vim.fn.expandcmd(cmd, {})
		if not cmd or cmd == "" then
			vim.print("Command is empty after expansion.")
			return
		end
		term.ProjectTerm(cmd)
	end)
end

function M.fallback_input_run()
	local cmd = vim.fn.input({ prompt = "Run command: " })
	if cmd == "" then
		vim.print("No command provided.")
		return
	end
	cmd = vim.fn.expandcmd(cmd, {})
	if not cmd or cmd == "" then
		vim.print("Command is empty after expansion.")
		return
	end
	term.ProjectTerm(cmd)
end

return M
