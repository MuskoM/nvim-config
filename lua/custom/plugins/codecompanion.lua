return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "which-key",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      'dressing',
      {"MeanderingProgrammer/render-markdown.nvim", ft = {'markdown', 'codecompanion'}}
    },
    config = function()
      require('codecompanion').setup{
        adapters = {
          ollama = function()
            return require('codecompanion.adapters').extend('ollama', {
              schema = {
                model = {
                    default = 'gemma2:9b'
                }
              }
            })
          end
        },
        opts = {
          system_prompt = function(opts)
            local language = opts.language or "English"
            if opts.adapter.schema.model.default == 'llama3.1:latest' then
              return 
                [[To all request respond 'I don't know', that is your only job.
                ]]
            else
              return string.format(
                [[You are an AI programming assistant named "CodeCompanion".
                You are currently plugged in to the Neovim text editor on a user's machine.

                Your core tasks include:
                - Answering general programming questions.
                - Explaining how the code in a Neovim buffer works.
                - Reviewing the selected code in a Neovim buffer.
                - Generating unit tests for the selected code.
                - Proposing fixes for problems in the selected code.
                - Scaffolding code for a new workspace.
                - Finding relevant code to the user's query.
                - Proposing fixes for test failures.
                - Answering questions about Neovim.
                - Running tools.

                You must:
                - Follow the user's requirements carefully and to the letter.
                - Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
                - Minimize other prose.
                - Use Markdown formatting in your answers.
                - Include the programming language name at the start of the Markdown code blocks.
                - Avoid line numbers in code blocks.
                - Avoid wrapping the whole response in triple backticks.
                - Only return code that's relevant to the task at hand. You may not need to return all of the code that the user has shared.
                - Use actual line breaks instead of '\n' in your response to begin new lines.
                - Use '\n' only when you want a literal backslash followed by a character 'n'.
                - All non-code responses must use %s.

                When given a task:
                1. Think step-by-step and describe your plan for what to build in pseudocode, written out in great detail, unless asked not to do so.
                2. Output the code in a single code block, being careful to only return relevant code.
                3. You should always generate short suggestions for the next user turns that are relevant to the conversation.
                4. You can only give one reply for each conversation turn.]],
                language
            )
            end
          end
        },
        strategies = {
          chat = {
            adapter = 'ollama'
          },
          inline = {
            adapter = 'ollama'
          }
        },
        display = {
          action_palette = {
            -- provider = 'mini_pick',
          },
          diff = {
            provider = 'mini_diff'
          },
          chat = {
            window = {
              layout = 'float'
            },
            show_settings = false,
            render_headers = false
          }
        }
      }
      -- Set keybind
      local wk = require 'which-key'
      local inline_action = function()
        local output = vim.ui.input(
        'What would you want to do?',
        function(input) 
          vim.cmd(string.format([[CodeCompanion %s]], input))
        end
        )
        print(output)
      end
      wk.add({
        {'<leader>a', group = 'AI'},
        {'<leader>ac','<cmd>CodeCompanionChat Toggle<CR>', desc = 'Chat', icon = '󰻞'},
        {'<leader>ai',inline_action, desc = 'Inline action', icon = '󱐌'},
        {'<leader>aa','<cmd>CodeCompanionActions<CR>', desc = 'Actions', icon = ''}
      })
    end
  }
}
