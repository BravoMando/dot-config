-- ~/.config/nvim/lua/mason.lua
require("mason").setup()

require("mason-tool-installer").setup({
  ensure_installed = {
    "clangd",
    "clang-tidy",
    "clang-format",
    "neocmakelsp",
    "cmakelang",
    "cmakelint",
    "cpplint",
  },
})
