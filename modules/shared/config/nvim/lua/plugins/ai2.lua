return {
  {
    "olimorris/codecompanion.nvim", -- The KING of AI programming
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "j-hui/fidget.nvim", -- Display status
      -- {
      --   "Davidyz/VectorCode", -- Index and search code in your repositories
      --   version = "*",
      --   build = "pipx upgrade vectorcode",
      --   dependencies = { "nvim-lua/plenary.nvim" },
      -- },
      -- { "echasnovski/mini.pick", config = true },
      -- { "ibhagwan/fzf-lua", config = true },
    },
    opts = {
      ---@module "codecompanion"
      ---@type CodeCompanion.Config
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            -- env = {
            --   api_key = "cmd:op read op://personal/Anthropic_API/credential --no-newline",
            -- },
            schema = {
              extended_thinking = {
                default = true,
              },
            },
          })
        end,
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = {
                default = "qwen3:latest",
              },
              num_ctx = {
                default = 20000,
              },
            },
          })
        end,
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            opts = {
              stream = true,
            },
            -- env = {
            --   api_key = "cmd:op read op://personal/OpenAI_API/credential --no-newline",
            -- },
            schema = {
              model = {
                default = function()
                  return "gpt-4.1"
                end,
              },
            },
          })
        end,
      },
      prompt_library = {
        ["Test workflow"] = {
          strategy = "workflow",
          description = "Use a workflow to test the plugin",
          opts = {
            index = 4,
          },
          prompts = {
            {
              {
                role = "user",
                content = "Generate a Python class for managing a book library with methods for adding, removing, and searching books",
                opts = {
                  auto_submit = false,
                },
              },
            },
            {
              {
                role = "user",
                content = "Write unit tests for the library class you just created",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Create a TypeScript interface for a complex e-commerce shopping cart system",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Write a recursive algorithm to balance a binary search tree in Java",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Generate a comprehensive regex pattern to validate email addresses with explanations",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Create a Rust struct and implementation for a thread-safe message queue",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Write a GitHub Actions workflow file for CI/CD with multiple stages",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Create SQL queries for a complex database schema with joins across 4 tables",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Write a Lua configuration for Neovim with custom keybindings and plugins",
                opts = {
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = "user",
                content = "Generate documentation in JSDoc format for a complex JavaScript API client",
                opts = {
                  auto_submit = true,
                },
              },
            },
          },
        },
      },
      strategies = {
        chat = {
          adapter = {
            name = "anthropic",
            model = "claude-sonnet-4-20250514",
            -- Options:
            -- claude-opus-4-20250514
            -- claude-sonnet-4-20250514
            -- claude-3-7-sonnet-20250219
            -- claude-3-5-sonnet-20241022
            -- claude-3-5-haiku-20241022
          },
          -- roles = {
          --   user = "olimorris",
          -- },
          keymaps = {
            send = {
              modes = {
                i = { "<C-CR>", "<C-s>" },
              },
            },
            completion = {
              modes = {
                i = "<C-x>",
              },
            },
          },
          slash_commands = {
            ["buffer"] = {
              keymaps = {
                modes = {
                  i = "<C-b>",
                },
              },
            },
            ["fetch"] = {
              keymaps = {
                modes = {
                  i = "<C-f>",
                },
              },
            },
            ["help"] = {
              opts = {
                max_lines = 1000,
              },
            },
            ["image"] = {
              keymaps = {
                modes = {
                  i = "<C-i>",
                },
              },
              -- opts = {
              --   dirs = { "~/Documents/Screenshots" },
              -- },
            },
          },
        },
        inline = {
          adapter = {
            name = "anthropic",
            -- model = "gpt-4.1",
          },
        },
      },
      display = {
        action_palette = {
          provider = "default",
        },
        chat = {
          -- show_references = true,
          -- show_header_separator = false,
          -- show_settings = false,
          icons = {
            tool_success = "󰸞",
          },
        },
        diff = {
          provider = "mini_diff",
        },
      },
      opts = {
        log_level = "DEBUG",
      },
    },
    keys = {
      {
        "<C-a>",
        "<cmd>CodeCompanionActions<CR>",
        desc = "Open the action palette",
        mode = { "n", "v" },
      },
      {
        "<Leader>a",
        "<cmd>CodeCompanionChat Toggle<CR>",
        desc = "Toggle a chat buffer",
        mode = { "n", "v" },
      },
      {
        "<LocalLeader>a",
        "<cmd>CodeCompanionChat Add<CR>",
        desc = "Add code to a chat buffer",
        mode = { "v" },
      },
    },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      -- require("plugins.custom.spinner"):init()
    end,
  },

  -- {
  --   'saghen/blink.cmp',
  --   dependencies = {
  --       'Kaiser-Yang/blink-cmp-avante',
  --       -- ... Other dependencies
  --   },
  --   opts = {
  --       sources = {
  --           -- Add 'avante' to the list
  --           default = { 'avante', 'lsp', 'path', 'luasnip', 'buffer' },
  --           providers = {
  --               avante = {
  --                   module = 'blink-cmp-avante',
  --                   name = 'Avante',
  --                   opts = {
  --                       -- options for blink-cmp-avante
  --                   }
  --               }
  --           },
  --       }
  --   }
  -- },

-- {
--   "yetone/avante.nvim",
--   event = "VeryLazy",
--   lazy = false,
--   version = false, -- set this if you want to always pull the latest change
--   opts = {
--     -- add any opts here
--     -- provider = "copilot",
--     provider = "claude",
--     auto_suggestions_provider = "claude-haiku", -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
--     providers = {
--         ---@type AvanteProvider
--         ollama = {
--             ['local'] = true,
--             endpoint = "http://localhost:11434/v1",
--             model = "llama3",
--             parse_curl_args = function(opts, code_opts)
--                 return {
--                     url = opts.endpoint .. "/chat/completions",
--                     headers = {
--                         ["Accept"] = "application/json",
--                         ["Content-Type"] = "application/json",
--                         ['x-api-key'] = 'ollama',
--                     },
--                     body = {
--                         model = opts.model,
--                         messages = require("avante.providers").copilot.parse_messages(code_opts), -- you can make your own message, but this is very advanced
--                         max_tokens = 2048,
--                         stream = true,
--                     },
--                 }
--             end,
--             parse_response_data = function(data_stream, event_state, opts)
--                 require("avante.providers").openai.parse_response(data_stream, event_state, opts)
--             end,
--         },
--         ---@type AvanteSupportedProvider
--         ["claude-haiku"] = {
--           endpoint = "https://api.anthropic.com",
--           model = "claude-3-5-haiku-20241022",
--           timeout = 30000, -- Timeout in milliseconds
--           ["local"] = false,
--         },
--         ---@type AvanteSupportedProvider
--         ["openai-mini"] = {
--           endpoint = "https://api.openai.com/v1",
--           model = "o1-mini", -- "gpt-4o-mini"
--           timeout = 16384, -- Timeout in milliseconds
--           ["local"] = false,
--         },
--         ---@type AvanteSupportedProvider
--         openai = {
--           endpoint = "https://api.openai.com/v1",
--           model = "gpt-4o",
--           timeout = 30000, -- Timeout in milliseconds
--           ["local"] = false,
--         },
--         ---@type AvanteSupportedProvider
--         copilot = {
--           endpoint = "https://api.githubcopilot.com",
--           model = "gpt-4o-2024-05-13",
--           proxy = nil, -- [protocol://]host[:port] Use this proxy
--           allow_insecure = false, -- Allow insecure server connections
--           timeout = 30000, -- Timeout in milliseconds
--         },
--         ---@type AvanteSupportedProvider
--         claude = {
--           endpoint = "https://api.anthropic.com",
--           model = "claude-3-5-sonnet-20241022",
--           timeout = 30000, -- Timeout in milliseconds
--           ["local"] = false,
--         },
--       },
--     behaviour = {
--       auto_suggestions = false, -- Experimental stage
--       auto_set_highlight_group = true,
--       auto_set_keymaps = true,
--       auto_apply_diff_after_generation = false,
--       support_paste_from_clipboard = false,
--     },
--     hints = { enabled = false },
--   },
--   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
--   build = "make",
--   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
--   dependencies = {
--     "nvim-treesitter/nvim-treesitter",
--     "stevearc/dressing.nvim",
--     "nvim-lua/plenary.nvim",
--     "MunifTanjim/nui.nvim",
--     --- The below dependencies are optional,
--     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
--     "zbirenbaum/copilot.lua", -- for providers='copilot'
--     {
--       -- support for image pasting
--       "HakonHarnes/img-clip.nvim",
--       event = "VeryLazy",
--       opts = {
--         -- recommended settings
--         default = {
--           embed_image_as_base64 = false,
--           prompt_for_file_name = false,
--           drag_and_drop = {
--             insert_mode = true,
--           },
--           -- required for Windows users
--           use_absolute_path = true,
--         },
--       },
--     },
--     {
--       -- Make sure to set this up properly if you have lazy=true
--       'MeanderingProgrammer/render-markdown.nvim',
--       opts = {
--         file_types = { "markdown", "Avante" },
--       },
--       ft = { "markdown", "Avante" },
--     },
--   },
-- }
}
