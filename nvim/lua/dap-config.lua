-- ~/.config/nvim/lua/dap-config.lua
require("mason-nvim-dap").setup({
  ensure_installed = {
    "codelldb",
  },
  automatic_installation = true,
  handlers = {},
})

local dap = require("dap")
dap.configurations.c = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
}
dap.configurations.cpp = dap.configurations.c

require("nvim-dap-virtual-text").setup({
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

require("dap-view").setup({
  auto_toggle = true,
  winbar = {
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
    default_section = "console",
    controls = {
      enabled = true,
      position = "right",
      buttons = { "play", "step_over", "step_into", "step_out", "terminate" },
    },
  },
  icons = {
    collapsed = '\xf3\xb0\x85\x82\x20',
    disabled = '\xef\x94\xaf',
    disconnect = '\xee\xab\x90',
    enabled = '\xef\x81\x98',
    expanded = '\xf3\xb0\x85\x80\x20',
    filter = '\xf3\xb0\x88\xb2',
    negate = '\xef\x81\x96\x20',
    pause = '\xee\xab\x91',
    play = '\xee\xab\x93',
    run_last = '\xee\xac\xb7',
    step_back = '\xee\xae\x8f',
    step_into = '\xee\xab\x94',
    step_out = '\xee\xab\x95',
    step_over = '\xee\xab\x96',
    terminate = '\xee\xab\x97',
  },
})

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<S-F5>", dap.terminate, { desc = "Debug: Terminate" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Debug: Terminate" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run Last" })

vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>B", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Conditional Breakpoint" })

vim.keymap.set("n", "<leader>dv", "<cmd>DapViewToggle<CR>", { desc = "Debug: Toggle DAP View" })
vim.keymap.set("n", "<leader>dc", "<cmd>DapViewClose<CR>", { desc = "Debug: Close DAP View" })
vim.keymap.set({ "n", "x" }, "<leader>dw", "<cmd>DapViewWatch<CR>", { desc = "Debug: Add to Watches" })

vim.keymap.set("n", "<leader>dW", "<cmd>DapViewJump watches<CR>", { desc = "Debug: Call Stack (Watches)" })
vim.keymap.set("n", "<leader>dS", "<cmd>DapViewJump scopes<CR>", { desc = "Debug: Variables (Scopes)" })
vim.keymap.set("n", "<leader>dE", "<cmd>DapViewJump exceptions<CR>", { desc = "Debug: Variables (Exceptions)" })
vim.keymap.set("n", "<leader>dB", "<cmd>DapViewJump breakpoints<CR>", { desc = "Debug: Variables (Breakpoints)" })
vim.keymap.set("n", "<leader>dT", "<cmd>DapViewJump threads<CR>", { desc = "Debug: Call Stack (Threads)" })
vim.keymap.set("n", "<leader>dR", "<cmd>DapViewJump repl<CR>", { desc = "Debug: REPL (Evaluate)" })
vim.keymap.set("n", "<leader>dC", "<cmd>DapViewJump console<CR>", { desc = "Debug: Console (Program I/O)" })

