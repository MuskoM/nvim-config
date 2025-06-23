local deploy_script_file = function()
  local filename = vim.fn.expand('%:t')
  local router_ip = '192.168.188.1'

  -- save file
  vim.cmd('write')

  -- SCP to router
  local scp_cmd = string.format('!scp %% admin@%s:', router_ip)
  vim.cmd(scp_cmd)

  -- Import in router
  local import_cmd = string.format('!ssh admin@%s "/import %s"', router_ip, filename)
  vim.cmd(import_cmd)

  print("Deployed " .. filename .. " to router!")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "routeros",
  callback = function()
    vim.api.nvim_create_user_command('MikroTikDeploy', deploy_script_file, {})
    vim.keymap.set('n', '<space>d', ':MikroTikDeploy<CR>', { buffer = true, desc = "Deploy Router OS script" })
  end
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.rsc",
  callback = function()
    vim.bo.filetype = "routeros"
  end
})
