return {
    {
        'yetone/avante.nvim',
        enabled = false,
        event = 'VeryLazy',
        lazy = false,
        version = false,
        build = 'make',
        opts = {
            provider = 'ollama',
            vendors = {
                ---@type AvanteProvider
                ollama = {
                    ["api_key_name"] = '',
                    endpoint = '127.0.0.1:11434/v1',
                    model = 'qwen2.5-coder:7b',
                    parse_curl_args = function(opts, code_opts)
                        return {
                            url = opts.endpoint .. 'chat/completions',
                            headers = {
                                ["Accept"] = 'application/json',
                                ["Content-Type"] = 'application/json',
                            },
                            body = {
                                model = opts.model,
                                messages = require('avante.providers').copilot.parse_messages(code_opts),
                                max_tokens = 2048,
                                stream = true,
                            }
                    }
                    end,
                    parse_response_data = function(data_stream, event_state, opts)
                        require('avante.providers').openai.parse_response(data_stream, event_state, opts)
                    end
                }
            }
        },
        dependencies = {
            'stevearc/dressing.nvim',
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            'echasnovski/mini.icons'
        }
    }
}
