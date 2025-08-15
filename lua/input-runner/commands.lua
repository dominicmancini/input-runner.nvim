-- In-progress file to refactor the commands in 'actions.lua' into
-- one 'IR' command with subcommands.

local M = {}

require("input-runner.api")
require("input-runner.extras")

local input = require("input-runner.input")

---@class IRSubcommand
---@field impl fun(args: string[], opts: table) The command implementation function.
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, IRSubcommand>
local subcommand_tbl = {

	set = { -- the command to set the env. vars
		impl = function(args, opts)
			-- check if user provided a command through args, and if not, then set it to the
			if args[1] and args[1] ~= "" then
				input.set_env_var(args[1])
			else
				input.input_set_cmd()
			end
		end,
		--
	},
}
