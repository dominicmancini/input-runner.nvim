-- Export API functions for input runner so that can easily make keymaps, etc.
local term = require("input-runner.term")
local config = require("input-runner.config")
local input = require("input-runner.input")
local actions = require("input-runner.actions")
local utils = require("input-runner.utils")

return {
	setup = config.setup,
	input_set_cmd = input.input_set_cmd,
	set_env_var = input.set_env_var,
	input_run_oneoff = input.input_run_oneoff,
	ProjectTerm = term.ProjectTerm,
	get_user_config = config.get_user_config,
	buf_is_file = utils.buf_is_file,
	get_env_var = input.get_env_var,
}
