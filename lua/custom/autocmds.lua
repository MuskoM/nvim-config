vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('advent-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank { timeout = 300 }
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
