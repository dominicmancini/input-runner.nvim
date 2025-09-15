local M = {}

local fts = require("input-runner.filetypes")
local conf = require("input-runner.config")
local utils = require("input-runner.utils")

---@alias InputRunner.run_type 'IR_CMD'|'IR_REPL'|'IR_INT' Used to represent the 'type' of run command, and potentially the Env. Var Name

---@alias Opts.ft string Filetype name (eg. 'python')

---@class FiletypeSpec.commands
---@field run? string Used for 'IR_RUN'
---@field repl? string Used for 'IR_REPL'
---@field int? string Used for 'IR_INT'

---@class FiletypeSpec
---@field command? string default, pre-expansion, command for filetype (eg. `python -u %:.`)
---@field kernel? string default jupyter kernel to use for filetype (will replace `$KERNEL` in command)
---@field commands? FiletypeSpec.commands default filetype commands for IR_RUN, IR_REPL, and IR_INT

---@class VarSpec
---@field name string? Variable Name Override
---@field default string? Default value (pre-expansion for commands)

---@class Opts.var_specs
---@field IR_CMD? VarSpec Run command spec
---@field IR_REPL? VarSpec REPL command spec
---@field IR_INT? VarSpec Interactive command spec

---@class Opts.env_vars
---@field IR_CMD? string? Run command variable
---@field IR_REPL? string REPL command variable
---@field IR_INT? string Interactive command variable

---@class NewOpts
---@field env_vars? Opts.env_vars table to override default names of the IR Environment variables
---@field ft_spec? table<Opts.ft, FiletypeSpec> Mapping of filetypes to default command configurations

local default_opts = {
	env_vars = {
		IR_CMD = "IR_CMD",
		IR_REPL = "IR_REPL",
		IR_INT = "IR_INT",
	},
	ft_spec = {
		python = {
			kernel = "python3",
			commands = {
				run = "python -m %:.:r:gs?/?.?",
				repl = "jupyter console --kernel=$KERNEL",
				int = "python -i %",
			},
		},
		r = {
			kernel = "ir",
			commands = {
				run = "Rscript %",
				repl = "jupyter console --kernel=$KERNEL",
			},
		},
	},
}

local merged_opts = {}

function M.setup_opts(user_opts)
	---@type NewOpts
	merged_opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})
end

---@return NewOpts
function M.get_merged_opts()
	return merged_opts
end

---@return NewOpts
function M.get_default_opts()
	return default_opts
end

---Check if user has specific (or any) filetype config
---@param opts NewOpts user opts
---@param ft? string Filetype (or nil)
function M.has_ft_config(opts, ft)
	local res
	if ft then
		res = vim.tbl_get(opts, "ft_spec", ft)
	else
		res = vim.tbl_get(opts, "ft_spec")
	end
	return res
end

---@param opts NewOpts
---@param default_name 'IR_CMD'|'IR_REPL'|'IR_INT'
function M.get_var_name(opts, default_name)
	local vars = vim.tbl_get(opts, "env_vars")
	if not vars then
		return default_name
	end
	local name = vars[default_name] or default_name

	return name
end

---comment
---@param opts NewOpts
---@param filetype string
---@param mode "run"|"repl"|"int"
function M.get_fallback(opts, filetype, mode)
	local cmd = vim.tbl_get(opts, "ft_spec", filetype, "commands", mode)
	if cmd == nil then
		return "Default cmd for " .. mode
	end
	if string.find(cmd, "$KERNEL") then
		local ft_kernel = vim.tbl_get(opts, "ft_spec", filetype, "kernel")
		print(ft_kernel)
		if ft_kernel and ft_kernel ~= "" then
			cmd = string.gsub(cmd, "$KERNEL", ft_kernel)
		end
	end
	return cmd
end

local var_type_map = {
	IR_CMD = "run",
	IR_REPL = "repl",
	IR_INT = "int",
}
---Determine the final command by going through precedence of config and present environment variables.
---@param ft string
---@param var_type InputRunner.run_type
---@param prompt? boolean Propt for cmd if none other is found?
function M.get_final_cmd(opts, ft, var_type, prompt)
	local var = vim.tbl_get(opts, "env_vars", var_type) or var_type
	local run_type = var_type_map[var_type]
	local method
	-- 1st. Get Env Var.
	local cmd = require("input-runner.input").get_env_var(var)
	if cmd and cmd ~= "" then
		method = "1. Environement Variable"
		return cmd
	end
	-- 2nd. Get Filetype-specfic var
	cmd = vim.tbl_get(opts, "ft_spec", ft, "commands", run_type)
	if cmd and cmd ~= "" then
		method = "2. Filetype-var"
		return cmd
	end
	-- 3rd. Prompt for cmd
	prompt = prompt ~= nil and prompt
	method = "3. Prompt or NIL"
	if prompt then
		cmd = require("input-runner.input").prompt_for_cmd("")
	end
	return cmd
end

return M
