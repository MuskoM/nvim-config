return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = {
            ensure_installed = {'lua', 'python', 'javascript', 'markdown', 'json', 'yaml'},
            sync_install = false,
            auto_install = true
        }
    }
}
