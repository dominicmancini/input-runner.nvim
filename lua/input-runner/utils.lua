local M = {}

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

return M
