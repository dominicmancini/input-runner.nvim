-- lua/config.lua
-- sets default config and loads user configuration
local M = {}

local fts = require("input-runner.filetypes")

---@alias InputRunner.ft string Filetype (eg. 'ft')

---@class InputRunner.Fallback
---@field kernel string Default kernel, can be used in place of $KERNEL
---@field IR_CMD string Fallback command, pre-expansion (`python -u %`)
---@field IR_REPL string fallback command, pre-expansion (`jupyter console --kernel=$KERNEL`)
---@field IR_INT string fallback interactive command, pre-expansion (eg. `ipython -i %:.`)

---@class InputRunner.Config
---@field command_var string? Environment variable name to use for the Input-Runner. Defaults to "IR_CMD"
---@field ui_select function? The `vim.ui.select` function to use instead of the default.
---@field repl_var string? Env. Variable name to use for IR REPL command. Defaults to "IR_REPL"
---@field interactive_var string? Env. variable name for IR interactive command.
---@field ft_spec table<InputRunner.ft, InputRunner.Fallback> A mapping of filetypes to default values of their respective commands. (Override Keys must be 'IR_*', but will respect the overriden var name during runtime)
---@type InputRunner.Config
local default_config = {
	command_var = "IR_CMD",
	ui_select = vim.ui.select,
	repl_var = "IR_REPL",
	interactive_var = "IR_INT",
	ft_spec = {},
}

local merged_config = {}

function M.setup(user_config)
	-- Merge user configuration with default configuration
	---@type InputRunner.Config
	merged_config = vim.tbl_deep_extend("force", {}, default_config, user_config or {})
end

---Get the merged user configuration
---@return InputRunner.Config merged_config The merged config table
M.get_user_config = function()
	-- Return the user configuration
	return merged_config
end

return M
