local M = {}

local constants = { SYSTEM_ROLE = 'system', USER_ROLE = 'user' }

---@class Message
---@field role string
---@field content function|table<string,any>
---@field opts? table<string,any>

---@class Prompt
---@field strategy string
---@field description string
---@field opts table<string, any>
---@field prompts Message[]
M.prompts = {
  ---@type Prompt
  ["Commit changes"] = {
    strategy = 'workflow',
    description = 'Create a commit with a meaningful message',
    opts = {},
    prompts = {
      {
        {
          role = constants.SYSTEM_ROLE,
          content = function(context)
            return
            'You are responsible for reviewing the git diff and creating a list of files that can be SAFELY commited to the remote repository. With that in mind also create a meaningful message for the commit.'
          end,
          opts = { auto_submit = false }
        },
        {
          role = constants.USER_ROLE,
          content = function(context)
            vim.g.codecompanion_auto_tool_mode = true
            return
            'Based on the generated file list add the files to staging and create a commit with earlier generated message. You can use the @cmd_runner to execute your task, remember you are not allowed to execute commands other than git'
          end,
          opts = { auto_submit = false }
        },
      }
    }
  },
  ["Documentation"] = {
    strategy = 'chat',
    description = "Create documentation for a piece of code",
    opts = {
      auto_submit = true,
      stop_context_insertion = true,
      user_prompt = false,
    },
    prompts = {
      {
        role = 'system',
        content = function(context)
          return string.format(
            [[You are an experienced software engineer, you are responsible for providing documentation
for given piece of code, your job requires to be: concise, thorough and knowledgable.
Give only the documentation in the format required by the %s language. Don't touch the code for any reason, only the documentation for it.
]],
            context.filetype
          )
        end
      },
      {
        role = 'user',
        content = function(context)
          local text = ""
          if context.is_visual then
            text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
          else
            local buf_fn = require('codecompanion.utils.buffers')
            text = buf_fn.get_content(context.bufnr)
          end
          return string.format(
            [[I have the following code:

```%s
%s
```
Write a documentation for it following best practices for writing %s code documentation
]],
            context.filetype,
            text,
            context.filetype
          )
        end,
        {
          contains_code = true
        }
      }
    }
  }
}

return M
