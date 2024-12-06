return {
  {
    'stevearc/dressing.nvim',
    name = 'dressing',
    config = function()
      require('dressing').setup {
        input = {
          title_pos = 'center'
        },
        select = {
          
        }
      }
    end
  }
}
