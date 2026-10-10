-- ~/.config/nvim/lua/dap-config.lua
require("mason").setup({
  ensure_installed = {
    "clangd",
    "neocmakelsp",
    "clang-format",
    "cmakelang",
    "cpplint",
    "cmakelint",
  },
  automatic_installation = true,
})
require("mason-nvim-dap").setup({
  ensure_installed = {
    "codelldb",
    "cppdbg",
  },
  automatic_installation = true,
  handlers = {},
})

local dap = require("dap")
dap.configurations.c = {
  {
    name = 'Launch',
    type = 'codelldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}
dap.configurations.cpp = dap.configurations.c

require('nvim-dap-virtual-text').setup({
  enabled = true,
  enabled_commands = true,
  highlight_changed_variables = true,
  highlight_new_as_changed = false,
  show_stop_reason = true,
  commented = false,
  only_first_definition = true,
  all_references = false,
  clear_on_continue = false,
})

require('dap-view').setup({
    winbar = {
        show = true,
        sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
        default_section = "console",
        show_keymap_hints = true,
        separators = nil,
        base_sections = {
            breakpoints = { label = "Breakpoints", keymap = "B" },
            scopes = { label = "Scopes", keymap = "S" },
            exceptions = { label = "Exceptions", keymap = "E" },
            watches = { label = "Watches", keymap = "W" },
            threads = { label = "Threads", keymap = "T" },
            repl = { label = "REPL", keymap = "R" },
            sessions = { label = "Sessions", keymap = "K" },
            console = { label = "Console", keymap = "C" },
        },
        custom_sections = {},
        controls = {
            enabled = false,
            position = "right",
            buttons = {
                "play",
                "step_into",
                "step_over",
                "step_out",
                "step_back",
                "run_last",
                "terminate",
                "disconnect",
            },
            custom_buttons = {},
        },
    },
    windows = {
        size = 0.25,
        position = "below",
        terminal = {
            size = 0.5,
            position = "left",
            hide = {},
        },
    },
    keymaps = {
        scopes = {
            toggle = { "<CR>", "<2-LeftMouse>" },
            jump_to_parent = "[[",
            set_value = "s",
        },
        watches = {
            toggle = { "<CR>", "<2-LeftMouse>" },
            jump_to_parent = "[[",
            set_value = "s",
            copy_value = "c",
            delete_expression = "d",
            append_expression = "a",
            insert_expression = "i",
            edit_expression = "e",
        },
        hover = {
            quit = "q",
            toggle = { "<CR>", "<2-LeftMouse>" },
            jump_to_parent = "[[",
            set_value = "s",
        },
        help = {
            quit = "q",
        },
        console = {
            next_session = "]s",
            prev_session = "[s",
        },
        threads = {
            toggle_subtle_frames = "t",
            filter = "f",
            invert_filter = "o",
            jump_to_frame = { "<CR>", "<2-LeftMouse>" },
            force_jump = "<C-w><CR>",
        },
        exceptions = {
            toggle_filter = { "<CR>", "<2-LeftMouse>" },
        },
        sessions = {
            switch_session = { "<CR>", "<2-LeftMouse>" },
        },
        breakpoints = {
            delete_breakpoint = "d",
            jump_to_breakpoint = { "<CR>", "<2-LeftMouse>" },
            force_jump = "<C-w><CR>",
        },
        base = {
            next_view = "]v",
            prev_view = "[v",
            jump_to_first = "[V",
            jump_to_last = "]V",
            help = "g?",
        },
    },
    icons = {
        collapsed = "󰅂 ",
        disabled = "",
        disconnect = "",
        enabled = "",
        expanded = "󰅀 ",
        filter = "󰈲",
        negate = " ",
        pause = "",
        play = "",
        run_last = "",
        step_back = "",
        step_into = "",
        step_out = "",
        step_over = "",
        terminate = "",
    },
    help = {
        border = nil,
    },
    hover = {
        border = nil,
    },
    render = {
        sort_variables = nil,
        threads = {
            format = function(name, lnum, path)
                return {
                    { text = name, separator = " " },
                    { text = path, hl = "FileName", separator = ":" },
                    { text = lnum, hl = "LineNumber" },
                }
            end,
            align = false,
        },
        breakpoints = {
            format = function(line, lnum, path)
                return {
                    { text = path, hl = "FileName" },
                    { text = lnum, hl = "LineNumber" },
                    { text = line, hl = true },
                }
            end,
            align = false,
        },
    },
    virtual_text = {
        enabled = false,
        position = "inline",
        format = function(variable)
            return " " .. variable.value
        end,
        prefix = function(position, node, bufnr)
            if position == "eol" or position == "eol_right_align" then
                local name = vim.treesitter.get_node_text(node, bufnr)

                return name .. " ="
            end
        end,
        suffix = function(position, _, _, var_index, num_var_line)
            if position == "eol" or position == "eol_right_align" then
                return var_index == num_var_line and "" or ","
            end
        end,
    },
    switchbuf = "usetab,uselast",
    auto_toggle = true,
    follow_tab = false,
})

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, { desc = 'Debug: Set Conditional Breakpoint' })
vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
vim.keymap.set('n', '<leader>dl', dap.run_last, { desc = 'Debug: Run Last' })

vim.keymap.set('n', '<leader>dv', '<cmd>DapViewToggle<CR>', { desc = 'Debug: Toggle DAP View' })