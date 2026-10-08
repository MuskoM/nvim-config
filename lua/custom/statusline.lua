-- Statusline: Neovim's default, with the mode and macro recording in front.
--
-- Both used to be command-line messages ('showmode'), and noice skips those
-- (its msg_showmode route), so "-- INSERT --" and "recording @q" were never
-- shown anywhere. Pending keys ('showcmd') go through the default's own %S
-- item, via showcmdloc=statusline in options.lua.
--
-- Built on the default rather than replacing it, so file name, diagnostics,
-- LSP progress and the ruler keep working as upstream changes them.
local M = {}

local labels = {
  n = 'NORMAL',
  no = 'O-PENDING',
  v = 'VISUAL',
  V = 'V-LINE',
  ['\22'] = 'V-BLOCK',
  s = 'SELECT',
  S = 'S-LINE',
  ['\19'] = 'S-BLOCK',
  i = 'INSERT',
  R = 'REPLACE',
  c = 'COMMAND',
  t = 'TERMINAL',
}

function M.prefix()
  local mode = vim.api.nvim_get_mode().mode
  local label = labels[mode] or labels[mode:sub(1, 1)] or mode
  local parts = { '%#ModeMsg# ' .. label .. ' %*' }
  local reg = vim.fn.reg_recording()
  if reg ~= '' then
    parts[#parts + 1] = '%#DiagnosticWarn#recording @' .. reg .. '%* '
  end
  return table.concat(parts, ' ') .. ' '
end

local default = vim.api.nvim_get_option_info2('statusline', {}).default
vim.o.statusline = "%{%v:lua.require'custom.statusline'.prefix()%}" .. default

-- The statusline is not redrawn on every mode switch or when recording
-- starts and stops, so ask for it.
vim.api.nvim_create_autocmd({ 'ModeChanged', 'RecordingEnter' }, {
  group = vim.api.nvim_create_augroup('custom-statusline', { clear = true }),
  command = 'redrawstatus',
})
-- reg_recording() still returns the register during RecordingLeave, so the
-- redraw has to wait until the recording has actually ended.
vim.api.nvim_create_autocmd('RecordingLeave', {
  group = 'custom-statusline',
  callback = function()
    vim.schedule(function()
      vim.cmd.redrawstatus()
    end)
  end,
})

return M
