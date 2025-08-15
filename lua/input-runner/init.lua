-- Initialize neovim plugin and get user configuration table
-- This file should also export the API functions for easy access by doing
-- -- `require("input-runner").<function_name>`
local InputRunner = {}

---Set up the input-runner plugin
---@param user_opts InputRunner.Config?
function InputRunner.setup(user_opts)
	-- TODO: implement a user configuration (not neccessary rn)
	require("input-runner.config").setup(user_opts)
	-- this will be used to create the user commands when the plugin is loaded
	require("input-runner.actions").setup()
	-- create and load the plug mappings
	require("input-runner.mappings").setup()
end

return InputRunner
