return {
  -- Java support is started per-buffer from after/ftplugin/java.lua, not with
  -- vim.lsp.enable() in lsp.lua like your other servers.
  --
  -- Why: jdtls keeps a stateful compiled model of the project in a workspace
  -- directory on disk, one per project root. The single global client that
  -- vim.lsp.enable() creates cannot express that. nvim-jdtls provides
  -- start_or_attach, which reuses a client when the root matches.
  {
    'mfussenegger/nvim-jdtls',
    ft = 'java',
    -- Also start jdtls as soon as nvim opens in a Gradle project, before any
    -- Java buffer exists, so the import runs while you pick a file. See
    -- custom/java.lua for why and for the reuse invariant.
    --
    -- `init` rather than `config`: config only runs once the plugin loads,
    -- which is the `ft = 'java'` trigger this is trying to get ahead of.
    -- start_for_cwd require()s jdtls itself, which loads it through lazy.
    --
    -- Only when nvim was given no file, or a directory (`nvim .`). With a file
    -- argument the ftplugin handles it -- and for a non-Java file, booting a
    -- JVM nobody asked for is the wrong default.
    --
    -- vim.schedule so the UI draws first; startup does not wait on the start.
    init = function()
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          local argv = vim.fn.argv()
          local dir
          if #argv == 0 then
            dir = vim.uv.cwd()
          elseif #argv == 1 and vim.fn.isdirectory(argv[1]) == 1 then
            dir = argv[1]
          else
            return
          end
          vim.schedule(function()
            require('custom.java').start_for_dir(dir)
          end)
        end,
      })
    end,
  },
}
