package.loaded["input-runner.fallbacks"] = nil
package.loaded["input-runner.config"] = nil

local fallbacks = require("input-runner.fallbacks")

---@type NewOpts
local user_opts = {
	env_vars = {
		IR_INT = "INTERACTIVE_CMD",
	},
	ft_spec = {
		python = {
			kernel = "datascience",
			commands = {
				run = "pyrunner.py %:p",
				int = "ipyrunner.py -i %:p",
				repl = "jupyter console --kernel=$KERNEL",
			},
		},
		r = {
			kernel = "ir",
			commands = {
				run = "Rscript %",
				repl = "radian",
				int = "jupyter console --kernel=$KERNEL",
			},
		},
		lua = {
			commands = {
				run = "nvim -l %",
			},
		},
	},
}
local tests = {
	{ "lua", "IR_CMD" },
	{ "python", "IR_INT" },
	{ "r", "IR_REPL" },
	{ "sh", "IR_CMD" },
}

local function do_fallbacks(tests)
	fallbacks.setup_opts(user_opts)
	local conf = fallbacks.get_merged_opts()
	local result = {}

	for i, t in ipairs(tests) do
		local res = fallbacks.get_final_cmd(conf, t[1], t[2]) or "NIL"
		table.insert(result, { test = t, res = res })
		-- result[i] = res
	end

	for i, val in ipairs(result) do
		print(val)
	end
end

local function get_ft_fallback(ft, runtype, config, prompt)
	local cmd
	local found = false
	---@type InputRunner.Fallback?
	local ft_spec = vim.tbl_get(config, "ft_spec", ft)
	print(ft_spec)
	if ft_spec and ft_spec[runtype] then
		cmd = ft_spec[runtype]
		if cmd and cmd ~= "" then
			return cmd
		end
	end
	return nil
	-- Check if kernel listed
end
local ft_spec = {
	python = {
		kernel = "python3",
		run = "python -m %:.:r:gs?/?.?",
		repl = "jupyter console --kernel=$KERNEL",
		int = "python -i %",
	},
	r = {
		kernel = "ir",
		run = "Rscript %",
		repl = "jupyter console --kernel=$KERNEL",
	},
}

local conf = require("input-runner.config").get_user_config()

local merged = vim.tbl_deep_extend("force", conf, user_opts)
-- print(merged)
local res = get_ft_fallback("lua", "IR_CMD", merged, false)
print(res)
-- for i, t in ipairs(tests) do
-- 	print(get_ft_fallback(t[1], t[2], merged, false))
-- end
--
