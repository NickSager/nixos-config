return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
      -- add any opts here
      -- provider = "copilot",
      provider = "claude",
      auto_suggestions_provider = "claude-haiku", -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
      vendors = {
          ---@type AvanteProvider
          ollama = {
              ['local'] = true,
              endpoint = "http://localhost:11434/v1",
              model = "llama3",
              parse_curl_args = function(opts, code_opts)
                  return {
                      url = opts.endpoint .. "/chat/completions",
                      headers = {
                          ["Accept"] = "application/json",
                          ["Content-Type"] = "application/json",
                          ['x-api-key'] = 'ollama',
                      },
                      body = {
                          model = opts.model,
                          messages = require("avante.providers").copilot.parse_messages(code_opts), -- you can make your own message, but this is very advanced
                          max_tokens = 2048,
                          stream = true,
                      },
                  }
              end,
              parse_response_data = function(data_stream, event_state, opts)
                  require("avante.providers").openai.parse_response(data_stream, event_state, opts)
              end,
          },
          ---@type AvanteSupportedProvider
          ["claude-haiku"] = {
            endpoint = "https://api.anthropic.com",
            model = "claude-3-5-haiku-20241022",
            timeout = 30000, -- Timeout in milliseconds
            temperature = 0,
            max_tokens = 8000,
            ["local"] = false,
          },
          ---@type AvanteSupportedProvider
          ["openai-mini"] = {
            endpoint = "https://api.openai.com/v1",
            model = "o1-mini", -- "gpt-4o-mini"
            timeout = 16384, -- Timeout in milliseconds
            temperature = 0,
            max_tokens = 4096,
            ["local"] = false,
          },
        },
      ---@type AvanteSupportedProvider
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o",
        timeout = 30000, -- Timeout in milliseconds
        temperature = 0,
        max_tokens = 16384,
        ["local"] = false,
      },
      ---@type AvanteSupportedProvider
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "gpt-4o-2024-05-13",
        proxy = nil, -- [protocol://]host[:port] Use this proxy
        allow_insecure = false, -- Allow insecure server connections
        timeout = 30000, -- Timeout in milliseconds
        temperature = 0,
        max_tokens = 4096,
      },
      ---@type AvanteSupportedProvider
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3-5-sonnet-20241022",
        timeout = 30000, -- Timeout in milliseconds
        temperature = 0,
        max_tokens = 8000,
        ["local"] = false,
      },
      behaviour = {
        auto_suggestions = false, -- Experimental stage
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
      },
      hints = { enabled = false },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  }
}
