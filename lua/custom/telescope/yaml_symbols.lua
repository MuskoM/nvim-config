local M = {}
local pickers = require 'telescope.pickers'
local conf = require('telescope.config').values
local finders = require 'telescope.finders'

local function visit_yaml_node(node, name, yaml_path, result, file_path, bufnr)
  local key = ''
  if node:type() == 'block_mapping_pair' then
    local field_key = node:field('key')[1]
    key = vim.treesitter.get_node_text(field_key, bufnr)
  end

  if key ~= nil and string.len(key) > 0 then
    table.insert(yaml_path, key)
    local line, col = node:start()
    table.insert(result, {
      lnum = line + 1,
      col = col + 1,
      bufnr = bufnr,
      filename = file_path,
      text = table.concat(yaml_path, '.'),
    })
  end

  for node, name in node:iter_children() do
    visit_yaml_node(node, name, yaml_path, result, file_path, bufnr)
  end

  if key ~= nil and string.len(key) > 0 then
    table.remove(yaml_path, table.maxn(yaml_path))
  end
end

local function gen_from_yaml_nodes()
  return function(entry)
    return {
      value = entry,
      ordinal = entry.text,
      display = entry.text,
      filename = entry.filename,
      lnum = entry.lnum,
      text = entry.text,
      col = entry.col,
    }
  end
end

local yaml_symbols = function(opts)
  local yaml_path = {}
  local result = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
  local tree = vim.treesitter.get_parser(bufnr, ft):parse()[1]
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local root = tree:root()
  for node, name in root:iter_children() do
    visit_yaml_node(node, name, yaml_path, result, file_path, bufnr)
  end

  pickers.new(opts, {
    prompt_title = 'YAML symbols',
    finder = finders.new_table {
      results = result,
      entry_maker = gen_from_yaml_nodes(),
    },
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
  }):find()
end

M.setup = function()
  vim.keymap.set('n', '<localleader>ys', yaml_symbols, {})
end

return M
