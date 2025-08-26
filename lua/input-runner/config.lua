-- lua/config.lua
-- sets default config and loads user configuration
local M = {}

---@class InputRunner.Config
---@field command_var string? Environment variable name to use for the Input-Runner. Defaults to "IR_CMD"
---@field ui_select function? The `vim.ui.select` function to use instead of the default.

---@type InputRunner.Config
local default_config = {
	command_var = "IR_CMD",
	ui_select = vim.ui.select,
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
