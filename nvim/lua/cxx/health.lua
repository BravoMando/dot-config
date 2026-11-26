-- nvim/lua/cxx/health.lua
local M = {}
function M.check()
  vim.health.start("C/C++ development")
  if vim.fn.has("nvim-0.12") == 1 then vim.health.ok("Neovim 0.12+") else vim.health.error("Neovim 0.12+ required") end
  for _, tool in ipairs({ "git", "cmake", "ctest", "ninja" }) do
    local path = vim.fn.exepath(tool)
    if path ~= "" then vim.health.ok(tool .. ": " .. path)
    else vim.health.warn(tool .. " missing from PATH", { "Install/expose Git, CMake and Ninja" }) end
  end
  vim.health.info("CMake selects the compiler and linker from the project toolchain, cache and environment; LLVM is recommended but optional")
  if vim.fn.executable("make") == 1 then
    vim.health.ok("make: " .. vim.fn.exepath("make"))
  else
    vim.health.info("make missing from PATH; only needed for Makefile projects")
  end
  for _, tool in ipairs({ "clangd", "clang-format", "neocmakelsp", "tree-sitter" }) do
    local path = vim.fn.exepath(tool)
    if path ~= "" then
      vim.health.ok(tool .. ": " .. path)
    else
      local advice = { "Run :DevToolsInstall and inspect :MasonLog" }
      if tool == "clang-format" then
        advice = { "Mason clang-format requires Python 3 with venv", "Run :DevToolsInstall and inspect :MasonLog" }
      end
      vim.health.warn(tool .. " not ready", advice)
    end
  end
  local suffix = vim.fn.has("win32") == 1 and ".exe" or ""
  local adapter = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb" .. suffix
  if vim.fn.executable(adapter) == 1 then vim.health.ok("CodeLLDB installed")
  else vim.health.warn("CodeLLDB not ready", { "Run :DevToolsInstall" }) end
  local root = require("project").root()
  local database = require("project").build_dir(root) .. "/compile_commands.json"
  if vim.fn.filereadable(database) == 1 or vim.fn.filereadable(root .. "/compile_commands.json") == 1 then
    vim.health.ok("Compilation database found")
  else
    vim.health.warn("No compilation database in project root/build directory", { "Open a CMake project and run :DevConfigure" })
  end
  for _, tool in ipairs({ "fzf", "rg" }) do
    local path = vim.fn.exepath(tool)
    if path ~= "" then vim.health.ok(tool .. ": " .. path)
    else vim.health.warn(tool .. " missing from PATH", { "Install fzf and ripgrep for project search" }) end
  end
  if vim.fn.executable("fd") == 1 or vim.fn.executable("fdfind") == 1 then
    vim.health.ok("fd file search available")
  else
    vim.health.info("fd not found; file search uses rg --files when available")
  end
  if vim.fn.has("win32") == 1 then
    vim.health.info("Use the SDK and C/C++ runtime required by your project toolchain; launch from a VS developer environment when using MSVC libraries")
  end
end
return M
