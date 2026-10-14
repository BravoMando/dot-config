-- ~/.config/nvim/lua/mason.lua
require("mason").setup()

require("mason-tool-installer").setup({
  ensure_installed = {
    "clangd",
--    "neocmakelsp",
--    "clang-format",
--    "gersemi",
--    "cmakelint",
--    "lua-language-server",
  },
})
