# input-runner.nvim

A Neovim plugin to run and manage shell commands and terminals directly from your editor, with support for environment-based command storage, quick mappings, and extensible actions.

## Features

- Execute any code, shell commands, etc. in a floating term window.
- Store and recall commands using environment variables (e.g., `$IR_CMD`, `$IR_CMD2`, ...)
- Environment Variables are passed to `vim.fn.expandcmd()` internally:
    * This allows you to use any vim filename-modifier syntax (eg. `%:p` - full path of current buffer) in commands.
    * See `:h filename-modifiers`
- Customizable `<Plug>` mappings for quick command execution
- User commands for setting, running, and selecting commands
- Extensible Lua API for advanced workflows

## Usage

Usage with `dotenv.nvim` is encouraged, which will allow you to set project-specific IR env-vars and automatically (or manually) load them.

For example, in `~/my_project/.env` I have the following:

```bash
IR_CMD="python main.py" # use static filename (eg. project entry-point)
IR_CMD2="python %:p" # or dynamic path using filename-modifiers
```
Then, set the following keymap in your config.

```lua
vim.keymap.set("n", "<leader>ir", "<cmd>IRRun<CR>", { noremap = true, desc = "Run $IR_CMD" })
vim.keymap.set("n", "<leader>2", "<Plug>(IRRun2)", { noremap = true, desc = "Run $IRCMD2"})
-- rest of <Plug> mappings 2-9
```
See [Commands for Additional Usage](#commands)

## Installation

Use your favorite plugin manager. For example, with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "dominicmancini/input-runner.nvim",
	dependencies = {
		"akinsho/toggleterm.nvim", -- Required
	},
    config = function()
        require("input-runner").setup()
    end
}
```

## Commands

- `:IRSetCmd [cmd]` — Set the main Input-Runner command (prompts if not provided)
- `:IRRun` — Run the command set in the Input-Runner environment variable (same for `IRRun<1-9>`)
- `:IRNewRun` — Input and run a new command (without setting Input-Runner)
- `:IRSelectCmd` — Select and run a command from all Input-Runner environment variables
- `:IRLastCmd` — Run the last command executed by Input-Runner
- `:IR {cmd}` — Run a command in the Input-Runner terminal (like `:!`, but in the IR floating terminal)

## Mappings

The plugin defines `<Plug>` mappings for easy integration:

- `<Plug>(IRSetCmd)` — Set the main command
- `<Plug>(IRRun)` — Run the main command
- `<Plug>(IRRun1)` ... `<Plug>(IRRun9)` — Run commands from `$IR_CMD1` ... `$IR_CMD9`

You can map these in your `init.lua` or `init.vim`, for example:

```lua
vim.keymap.set("n", "<leader>rr", "<Plug>(IRRun)")
vim.keymap.set("n", "<leader>rs", "<Plug>(IRSetCmd)")
vim.keymap.set("n", "<leader>r1", "<Plug>(IRRun1)")
```

## Configuration

You can configure the plugin by passing options to `setup`. The only option currently is the environment variable prefix:

```lua
require("input-runner").setup({
  command_var = "IR_CMD", -- default, change if you want a different prefix
})
```

## API

You can require and use the plugin's Lua API in your own code:

```lua
local ir = require("input-runner")
-- ir.setup(), etc.
```

## Terminal Integration

Commands are run in floating terminals using [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim). The terminal window is styled and sized automatically.

## Requirements

- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
