return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "which-key",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      'dressing',
      { "MeanderingProgrammer/render-markdown.nvim", ft = { 'markdown', 'codecompanion' } }
    },
    config = function()
      require('codecompanion').setup {
        extensions = {
          mcphub = {
            callback = "mcphub.extensions.codecompanion",
            opts = {
              make_tools = true,
              show_server_tools_in_chat = true,
              add_mcp_prefix_to_tool_names = false,
              show_results_in_chat = true,
              format_tool = nil,
              make_vars = true,
              make_slash_commands = true
            }
          }
        },
        adapters = {
          ollama = function()
            return require('codecompanion.adapters').extend('ollama', {
              schema = {
                model = {
                  default = 'qwen3:8b'
                }
              }
            })
          end,
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key =
                "API_KEY",
              },
            })
          end,
        },
        opts = {
          system_prompt = function(opts)
            local language = opts.language or "English"
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
                - Keep your answers short and concise, especially if the user responds with context outside of your tasks.
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
        },
        strategies = {
          chat = {
            adapter = 'anthropic'
          },
          inline = {
            adapter = 'anthropic',
            keymaps = {
              reject_change = {
                modes = {
                  n = 'gd'
                }
              }
            },
            prompts = {
              inline_to_chat = function(context)
                return string.format(
                  [[I want you to act as an expert and senior developer in %s language. I will ask you questions, perhaps giving you code examples, and I want you to advise me with explanations and code where neccessary.CodeCompanion
                  - Return plain text only
                  - Do not wrap your response in a markdown block or backticks
                  ]],
                  context.filetypes
                )
              end,
            }
          }
        },
        display = {
          action_palette = {
          },
          diff = {
            provider = 'mini_diff'
          },
          chat = {
            window = {
              layout = 'vertical'
            },
            show_settings = false,
            render_headers = false
          }
        },
        -- Prompt Library
        prompt_library = require('custom.codecompanion.prompt_library').prompts
      }


      -- Set keybind
      local wk = require 'which-key'
      local inline_action = function()
        local output = vim.ui.input(
          { prompt = 'What would you want to do?', default = '' },
          function(input)
            vim.cmd(string.format([[CodeCompanion %s]], input))
          end
        )
      end
      wk.add({
        { '<leader>a', group = 'AI' },
        { '<leader>ac', '<cmd>CodeCompanionChat Toggle<CR>', desc = 'Chat', icon = '󰻞', mode = { 'n', 'v' } },
        { '<leader>ai', inline_action, desc = 'Inline action', icon = '󱐌', mode = 'n' },
        { '<leader>aa', '<cmd>CodeCompanionActions<CR>', desc = 'Actions', icon = '', mode = { 'n', 'v', } },
        { 'ga', '<cmd>CodeCompanionChat Add<CR>', desc = 'Add selection to current AI chat', icon = '', mode = { 'n', 'v', } },
      })
    end
  }
}
