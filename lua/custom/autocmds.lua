vim.opt.autoread = true

vim.api.nvim_create_autocmd({'FocusGained','BufEnter', 'CursorHold', 'TermClose', 'TermLeave'}, {
  desc = 'Reload buffers changed on disk (agents write files out from under us)',
  group = vim.api.nvim_create_augroup('agent-file-sync', {clear = true}),
  callback = function ()
    if vim.bo.buftype == '' and vim.fn.mode() ~= 'c' then vim.cmd('checktime') end
  end,
})

vim.api.nvim_create_autocmd({'FileChangedShellPost'}, {
  desc = 'Say so, rather than moving the text under the cursor in silence',
  group = 'agent-file-sync',
  callback = function() vim.notify('Buffer reloaded from disk', vim.log.levels.WARN) end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('advent-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.hl_op { timeout = 300 }
  end
})

vim.api.nvim_create_autocmd('ColorScheme', {
  desc = 'Removes background color',
  group = vim.api.nvim_create_augroup('color-my-pencils', { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
  end
})



