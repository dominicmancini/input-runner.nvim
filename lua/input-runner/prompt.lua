local nui = require("nui.split")

local term = require("toggleterm.terminal")
local notify = function(msg)
	msg = vim.inspect(msg)
	require("fidget").notify(msg, vim.log.levels.INFO, { annote = "Prompt" })
end

local t = term.Terminal:new({
	cmd = "jupyter console",
	close_on_exit = true,
	direction = "vertical",
	auto_scroll = true,
	on_open = function(term)
		if term:is_focused() then
			vim.cmd("wincmd h")
		end
	end,
	on_exit = function(t, job, exit_code, name)
		notify({ "Exited: ", job = job, exit_code = exit_code })
	end,
})

local split = nui({
	relative = "win",
	buf_options = { buftype = "prompt", bufhidden = "wipe", filetype = "python" },
	ns_id = "input-runner",
	position = "bottom",
	enter = true,
})

local function exit_cb()
	vim.bo[split.bufnr].modified = false
	split:unmount()
	t:shutdown()
end

split:map("n", "q", function()
	exit_cb()
	-- vim.bo[split.bufnr].modified = false
	-- split:unmount()
	--   t:shutdown()
end)

t:open()

split:mount()

vim.fn.prompt_setprompt(split.bufnr, "> ")

vim.fn.prompt_setcallback(split.bufnr, function(line)
	if not line then
		return
	end
	if line == "quit" or line == "exit" then
		exit_cb()
		return
		-- notify("Exiting Prompt Buffer")
		-- vim.bo[split.bufnr].modified = false
		-- split:unmount()
	end
	t:send(line, true)
end)
