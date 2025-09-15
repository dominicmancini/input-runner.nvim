local M = {}
local input = require("input-runner.input")
local config = require("input-runner.config").get_user_config()
local term = require("input-runner.term")
local utils = require("input-runner.utils")
local interactive = require("input-runner.interactive")
-- NOTE: repl required in IRRepl command

function M.setup()
	vim.api.nvim_create_user_command("IRSetCmd", function(args)
		-- check if user provided a command through args and set it, if not, prompt for one
		if args.args and args.args ~= "" then
			input.set_env_var(args.args)
		else
			input.input_set_cmd()
		end
	end, {
		desc = " Set the Input-Runner environment variable",
		nargs = "?", -- allows for an optional argument
	})

	vim.api.nvim_create_user_command("IRRun", function()
		local cmd = input.get_env_var()
		if not cmd then
			cmd = input.input_set_cmd()
		end
		input.default_launch()
	end, {
		desc = "Run the command set in the Input-Runner environment variable",
	})

	vim.api.nvim_create_user_command("IRNewRun", function(args)
		input.input_run_oneoff()
	end, { desc = "Input and Run a new CMD (without setting Input-Runner)" })

	vim.api.nvim_create_user_command("IRSelectCmd", function(args)
		local prefix = config.command_var or "IR_CMD"
		local ir_vars = input.get_all_env_vars(prefix)
		-- local expanded_ir_vars = {}
		if not ir_vars or vim.tbl_isempty(ir_vars) then
			vim.notify("No commands found for " .. prefix, vim.log.levels.WARN)
			return
		end
		-- for k, v in pairs(ir_vars) do
		-- 	expanded_ir_vars[k] = vim.fn.expandcmd(v)
		-- end
		-- actual item user is selecting is the key (the env. variable name)
		local select = config.ui_select or vim.ui.select
		-- vim.ui.select(vim.tbl_keys(ir_vars), {
		select(vim.tbl_keys(ir_vars), {
			prompt = "Select a command to run",
			format_item = function(item)
				return ("%s | %s"):format(item, ir_vars[item])
			end,
		}, function(item, idx)
			local cmd = ir_vars[item]
			if not cmd or cmd == "" then
				vim.notify("Command for " .. item .. " is empty", vim.log.levels.ERROR, { title = "Input-Runner" })
				return
			end
			-- Item needs to be expanded
			cmd = input.prepare_and_remember_cmd(cmd)
			if not cmd or cmd == "" then
				vim.notify(
					"Command for " .. item .. " is empty after expansion",
					vim.log.levels.ERROR,
					{ title = "Input-Runner" }
				)
				return
			end
			term.ProjectTerm(cmd)
		end)
	end, {
		desc = "Select and run a command from the Input-Runner environment variables",
	})

	vim.api.nvim_create_user_command("IRLastCmd", function(args)
		-- get last command from var 'vim.g.IR_last_cmd'
		local last_cmd = vim.g.IR_last_cmd
		if not last_cmd or last_cmd == "" then
			vim.notify("No last command found", vim.log.levels.WARN, { title = "Input-Runner" })
			return
		end
		local cmd = input.prepare_and_remember_cmd(last_cmd)
		term.ProjectTerm(cmd, { display_name = "IR Last Command" })
	end, { desc = " Run the last command set in Input-Runner" })

	-- Command that acts like the ':!' except runs the command in the input-runner terminal
	-- It should have a short name like ':!' but not conflict with existing commands
	-- For example, we can use ':IR!' or ':IRRun!'
	vim.api.nvim_create_user_command("IR", function(args)
		-- the command is provided only through the args
		local cmd = args.args
		if not cmd or cmd == "" then
			vim.notify("No command provided for IR", vim.log.levels.ERROR, { title = "Input-Runner" })
			return
		end
		local expanded_cmd = input.prepare_and_remember_cmd(cmd)
		if not expanded_cmd or expanded_cmd == "" then
			vim.notify("Command is empty after expansion", vim.log.levels.ERROR, { title = "Input-Runner" })
			return
		end
		term.ProjectTerm(cmd)
	end, { desc = "Run a command in the Input-Runner terminal", nargs = "*", complete = "shellcmdline" })

	vim.api.nvim_create_user_command("IRRepl", function(args)
		local var = config.repl_var or "IR_REPL"
		local cmd = input.get_env_var(var)
		if not cmd then
			cmd = input.prompt_for_cmd("")
		end
		-- NOTE: Cmd validation already happens in 'Repl_term'
		-- if not cmd or cmd == "" then
		-- 	vim.notify("REPL Aborted - CMD Empty", vim.log.levels.WARN, { title = "Input-Runner"})
		-- 	return
		-- end
		require("input-runner.repl").Repl_term(cmd)
	end, { desc = "Start REPL with command defined in the IR_REPL env. var, or start a new one." })

	vim.api.nvim_create_user_command("IRInteractive", function(args)
		local var = config.interactive_var or "IR_INT"
		local cmd = args.args
		if not cmd or cmd == "" then
			---@diagnostic disable-next-line:cast-local-type
			cmd = input.get_env_var(var)
			-- Using env. variable, if there
		end
		if not cmd or cmd == "" then
			vim.notify(
				("No command provided or found in var '$%s'"):format(var),
				vim.log.levels.ERROR,
				{ title = "Input-Runner" }
			)
			return
		end
		local expanded_cmd = vim.fn.expandcmd(cmd)
		if utils.nil_or_empty(expanded_cmd) then
			vim.notify(
				vim.inspect("Expanded Cmd is nil or empty: ", expanded_cmd),
				vim.log.levels.ERROR,
				{ title = "Input-Runner" }
			)
			return
		end
		local buf = vim.api.nvim_get_current_buf()
		local scratch_ft = vim.bo[buf].filetype or "python"
		-- require("input-runner.interactive").Interactive_Term(cmd, nil, scratch_ft, true)
		interactive.Interactive_Term(expanded_cmd, nil, scratch_ft, true)
	end, { nargs = "*", complete = "shellcmdline", desc = "Run the file interactively." })
end

return M
