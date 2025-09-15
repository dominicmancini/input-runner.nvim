package.loaded["input-runner.interactive"] = nil
local ir = require("input-runner.interactive")

local function file_int_test()
	local prog = "ipyrunner"
	if vim.fn.executable(prog) ~= 1 then
		vim.notify("Error, 'ipyrunner' is not executable", vim.log.levels.ERROR)
		return
	end
	local f = vim.fs.find("scrip.py", { limit = 1 })[1]
	local cmd = ("%s -i %s"):format(prog, f)
	ir.Interactive_Term(cmd, {}, "python", true)
end

local function test(cmd, file)
	local term = ir.Interactive_Term(cmd, {}, "python", true)
	if not term then
		return
	end
	require("input-runner.comp").attach_kernel("datascience")
	term:send("%run " .. file)
	local code = require("input-runner.code")
end

local replcmd = "jupyter console --kernel=datascience"

vim.keymap.set("n", "<leader>`", function()
	-- ir.Interactive_Term(replcmd, {}, "python", true)
	file_int_test()
end, { desc = "Start Interactive Term" })
