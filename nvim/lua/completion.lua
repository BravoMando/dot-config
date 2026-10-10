-- ~/.config/nvim/lua/completion.lua

vim.opt.completeopt = 'menuone,noselect,popup,fuzzy'

local word_chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'

local function add_word_triggers(client)
  local provider = client.server_capabilities.completionProvider
  if not provider then
    return
  end
  provider.triggerCharacters = provider.triggerCharacters or {}
  local seen = {}
  for _, char in ipairs(provider.triggerCharacters) do
    seen[char] = true
  end
  for char in word_chars:gmatch('.') do
    if not seen[char] then
      table.insert(provider.triggerCharacters, char)
      seen[char] = true
    end
  end
end

local function set_keymaps(buf)
  vim.keymap.set({ 'i', 's' }, '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
      return '<C-n>'
    elseif vim.snippet.active({ direction = 1 }) then
      return '<Cmd>lua vim.snippet.jump(1)<CR>'
    end
    return '<Tab>'
  end, { buffer = buf, expr = true, silent = true, desc = 'LSP: Next item / snippet jump' })

  vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
    if vim.fn.pumvisible() == 1 then
      return '<C-p>'
    elseif vim.snippet.active({ direction = -1 }) then
      return '<Cmd>lua vim.snippet.jump(-1)<CR>'
    end
    return '<S-Tab>'
  end, { buffer = buf, expr = true, silent = true, desc = 'LSP: Previous item / snippet jump' })

  vim.keymap.set('i', '<CR>', function()
    if vim.fn.pumvisible() == 1 then
      if vim.fn.complete_info({ 'selected' }).selected == -1 then
        return '<C-n><C-y>'
      end
      return '<C-y>'
    end
    return '<CR>'
  end, { buffer = buf, expr = true, silent = true, desc = 'LSP: Accept completion / newline' })

  vim.keymap.set('i', '<Esc>', function()
    if vim.fn.pumvisible() == 1 then
      return '<C-e>'
    end
    return '<Esc>'
  end, { buffer = buf, expr = true, silent = true, desc = 'LSP: Close menu / normal Esc' })
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserCompletion', {}),
  callback = function(args)
    local clients = vim.lsp.get_clients({ bufnr = args.buf, method = 'textDocument/completion' })
    for _, client in ipairs(clients) do
      add_word_triggers(client)
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
    if #clients > 0 then
      set_keymaps(args.buf)
    end
  end,
})

