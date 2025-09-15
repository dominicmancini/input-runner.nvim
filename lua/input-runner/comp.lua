local M = {}

local kernel_map = {
	python = "python3",
	r = "ir",
}

function M.setup_completion()
	local ok, jupyter = pcall(require, "jupyter_kernel")
	if not ok then
		vim.notify("Problem importing 'jupyter_kernel'", vim.log.levels.ERROR)
		return
	end
	local blink = require("blink.cmp")
	local conf = require("blink.cmp.config")
	local has_src = conf.sources.providers["jupyter"] ~= nil
	if not has_src then
		blink.add_source_provider("jupyter", {
			module = "blink.compat.source",
			name = "jupyter",
			min_keyword_length = 0,
			score_offset = 100,
			fallbacks = { "lsp", "snippets" },
		})
	end
	blink.add_filetype_source("python", "jupyter")
end

---comment
---@param cmd string The terminal command
function M.parse_kernel(cmd, ft)
	-- local res = {cmd:find("--kernel=?(%w+)")}
	-- local res = {cmd:find("%--kernel[= ]?(%w+)")}
	local kernel = cmd:match("%--kernel[= ]?(%w+)")
	if not kernel or kernel == "" then
		kernel = kernel_map[ft] or "python3"
	end
	return kernel
end

function M.attach_kernel(kernel)
	require("jupyter_kernel").attach({ args = kernel })
end

function M.on_exit()
	require("blink.cmp.config").sources.per_filetype["python"] = nil
	require("blink.cmp").reload()
end

---@param interactive_buf integer Interactive, scratch buffer
---@param term Terminal Terminal Open
---@param ft? string Filetype
function M.setup_interactive_buf(interactive_buf, term, ft)
	ft = ft or vim.bo[interactive_buf].filetype
	local kernel = M.parse_kernel(term.cmd, ft) or ""
	-- if not kernel or kernel == "" then
	-- 	vim.notify("Could not Parse Kernel", vim.log.levels.WARN, { title = "Input-Runner" })
	-- end
	-- Sets up the blink source for jupyter
	M.setup_completion()

	-- Now attach kernel
	M.attach_kernel(kernel)

	-- Replace 'K' keymap for int. buf
	vim.keymap.set("n", "K", function()
		require("jupyter_kernel").inspect()
	end, { buffer = interactive_buf, desc = "Inspect Jupyter Variables" })
end

-- local cmds = {
-- 	"jupyter console --kernel=datascience",
-- 	"ipython kernel ir",
-- 	"jupyter console",
-- }
--
-- print(M.parse_kernel(cmds[1]), M.parse_kernel(cmds[2]), M.parse_kernel(cmds[3]))

return M
