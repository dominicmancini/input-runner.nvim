local term = require("input-runner.term")
local config = require("input-runner.config").get_user_config()
local command_var = config.command_var or "IR_CMD" -- Default to "IR_CMD" if not set in config

local M = {}

local levels = vim.log.levels

local notifopts = { title = "Input-Runner" }

---Expand the command and save it in `vim.g.IR_last_cmd`.
---@param raw_cmd string the raw command to expand
---@return string expanded The expanded command
function M.prepare_and_remember_cmd(raw_cmd)
	local expanded = vim.fn.expandcmd(raw_cmd)
	-- set the last command in global variable
	vim.g.IR_last_cmd = raw_cmd
	return expanded
end

local function prompt_for_cmd()
	local cmd = vim.fn.input({ prompt = "Set new command: ", default = os.getenv(command_var) or "" })
	return cmd
end

-- to enable 'last command', need to save a valid cmd in global var 'vim.g.IR_last_cmd' before it is expanded

---Set the command in `vim.g.IR_last_cmd` that is used by the `IRLastCmd` command.
---Needs to be set before command is expanded, so that it can be used for different files/buffers if containing path.
---@param raw_cmd string the pre-expanded command to set as last cmd.
local function set_last_cmd(raw_cmd)
	vim.g.IR_last_cmd = raw_cmd
end

---Launch a terminal with the environment variable command_var
function M.default_launch()
	-- get the value of the command_var environment variable if it exists
	local cmd = os.getenv(command_var)
	if not cmd then
		vim.notify(command_var .. " environment variable not set", vim.log.levels.ERROR)
		return
	end
	local expanded = M.prepare_and_remember_cmd(cmd)
	term.ProjectTerm(expanded)
end

---Set the environment variable command_var to the provided command
---@param cmd string The command to set as the environment variable
---@param var string? The name of the environment variable to set, defaults to command_var
function M.set_env_var(cmd, var)
	var = var or command_var
	vim.fn.setenv(var, cmd)
	vim.notify(("%s Set to: %s"):format(var, cmd), levels.INFO, notifopts)
end

---Promt for a command and set it to the
---@return string
function M.input_set_cmd()
	local cmd = prompt_for_cmd()
	M.set_env_var(cmd)
	return cmd
	-- term.projectTerm(cmd)
end

---Retrieve the value of the command_var var, or nil if not set
---@param var string?
---@return string? cmd The value of the command_var environment variable, or nil if not set
function M.get_env_var(var)
	var = var or command_var
	-- Get the value of the command_var environment variable
	local cmd = os.getenv(var)
	if not cmd then
		return nil
	end
	return cmd
end

---Get env variables for <prefix> and numbered variants (e.g. IR_CMD, IR_CMD1, ..., IR_CMD9) and their expanded command
---@param prefix string the prefix for the environment variable (e.g. "IR_CMD")
---@return table<`prefix`, string> ir_vars table with keys as the env var names and values as the expanded commands
function M.get_all_env_vars(prefix)
	local ir_vars = {}
	local main = os.getenv(prefix)
	if main then
		ir_vars[prefix] = main
	end
	for i = 1, 9 do
		local env_name = string.format("%s%d", prefix, i)
		local env_value = os.getenv(env_name)
		if env_value then
			ir_vars[env_name] = env_value
		end
	end
	return ir_vars
end

function M.input_run_oneoff()
	vim.ui.input({ prompt = "Run Command: " }, function(value)
		if not value or value == "" then
			vim.notify("No command provided.", levels.INFO, notifopts)
			return
		end
		local expanded = M.prepare_and_remember_cmd(value)
		term.ProjectTerm(value)
	end)
end

return M
