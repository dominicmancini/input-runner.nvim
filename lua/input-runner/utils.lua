local M = {}

local input = require("input-runner.input")
local config = require("input-runner.config").get_user_config()

function M.nil_or_empty(obj)
	if obj == nil then
		return true
	end
	if type(obj) == "string" then
		return obj == ""
	elseif type(obj) == "table" then
		return #obj == 0
	end
	return false
end

---Checks if the current buffer represents a real file.
---@param buf integer?
---@return boolean buf_is_file Buffer is a file?
function M.buf_is_file(buf)
	local bufnr = buf or vim.api.nvim_get_current_buf()
	local name = vim.fn.bufname(bufnr)
	if name == "" or name == nil then
		return false
	else
		return true
	end
end

function M.save_and_run()
	vim.cmd("update") -- Save the current buffer (if a file and modified)
	require("input-runner.input").default_launch()
end

---For commands to get the cmd var, going in order of precedence
---@param var_name string The env var to try and get.
---@param args string? Args passed directly from command
---@param prompt boolean? Prompt for value if not available (default false)
function M.precedence_cmd_var_get(args, var_name, prompt)
	prompt = prompt == nil or prompt
	args = args or ""
	if #vim.trim(args) > 0 then
		return args
	end
	local var = input.get_env_var(var_name)
	if not M.nil_or_empty(var) then
		return var
	end
	-- TODO: Implement fallback command in config
end

return M
