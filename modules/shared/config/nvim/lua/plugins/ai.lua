-- Get aws credentials from 'ada' command / or environment variable
function get_credentials(key_type)
    local bedrock_keys = os.getenv("BEDROCK_KEYS")
    if not bedrock_keys then
        return nil
    end

    local keys = {}
    for value in string.gmatch(bedrock_keys, "([^,]+)") do
        table.insert(keys, value)
    end

    if key_type == "AccessKeyId" then
        return keys[1]
    elseif key_type == "SecretAccessKey" then
        return keys[2]
    elseif key_type == "SessionToken" then
        return keys[4]
    end

    return nil
end

-- Parse bedrock streaming response into format expected by regular anthropic adapter
local function parse_bedrock_stream(chunk)
  local decoded_chunks = {}
  for bedrock_data_match in chunk:gmatch 'event(%b{})' do
    local ok, json_data = pcall(vim.json.decode, bedrock_data_match)
    if ok and json_data.bytes then
      local decoded_data = vim.base64.decode(json_data.bytes)
      table.insert(decoded_chunks, decoded_data)
    end
  end
  return decoded_chunks
end

-- Success marker from upstream anthropic adapter
local STATUS_SUCCESS = 'success'

-- Merge content strings
local function merge_content(target, source)
  if not source or source == '' then return target end
  return (target or '') .. source
end

-- Merge dicts of type { content: str, signature: str }
local function merge_reasoning(target, source)
  if not source then return target end
  target = target or { content = nil, signature = nil }
  target.content = merge_content(target.content, source.content)
  target.signature = merge_content(target.signature, source.signature)
  return target
end

return {
  {
    "olimorris/codecompanion.nvim", -- The KING of AI programming
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "j-hui/fidget.nvim", -- Display status
      -- {"ravitemer/mcphub.nvim",
      --   callback = "mcphub.extensions.codecompanion",
      --   opts = {
      --     make_vars = true,
      --     make_slash_commands = true,
      --     show_result_in_chat = true
      -- },
      -- {
      --   "Davidyz/VectorCode", -- Index and search code in your repositories
      --   version = "*",
      --   build = "pipx upgrade vectorcode",
      --   dependencies = { "nvim-lua/plenary.nvim" },
      -- },
      {
        "echasnovski/mini.diff",
        config = function()
          local diff = require("mini.diff")
          diff.setup({
            -- Disabled by default
            source = diff.gen_source.none(),
          })
        end,
      },
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

        bedrock = function()
          local anthropic = require 'codecompanion.adapters.anthropic'

          ---@class Bedrock.Adapter: CodeCompanion.Adapter
          return require('codecompanion.adapters').extend('anthropic', {
            name = 'bedrock',
            formatted_name = 'Bedrock',
            url = 'https://bedrock-runtime.${aws_region}.amazonaws.com/model/${model}/${endpoint}',
            env = {
              aws_access_key_id = function() return get_credentials 'AccessKeyId' end,
              aws_region = 'schema.region.default',
              aws_secret_access_key = function() return get_credentials 'SecretAccessKey' end,
              aws_session_token = function() return get_credentials 'SessionToken' end,
              endpoint = function(self)
                if self.opts.stream then
                  return 'invoke-with-response-stream'
                else
                  return 'invoke'
                end
              end,
              model = 'schema.model.default',
            },
            headers = {
              ['x-amz-security-token'] = '${aws_session_token}',
            },
            raw = {
              '--aws-sigv4',
              'aws:amz:${aws_region}:bedrock',
              '--user',
              '${aws_access_key_id}:${aws_secret_access_key}',
            },
            handlers = {
              setup = function(_) return true end,
              tokens = function(self, data)
                local total_tokens = 0
                if self.opts.stream then
                  for _, message in ipairs(parse_bedrock_stream(data)) do
                    total_tokens = total_tokens + (anthropic.handlers.tokens(self, message) or 0)
                  end
                else
                  total_tokens = anthropic.handlers.tokens(self, data)
                end
                return total_tokens
              end,
              chat_output = function(self, data, tools)
                if not self.opts.stream then return anthropic.handlers.chat_output(self, data, tools) end

                local output = { role = nil, reasoning = nil, content = nil }
                local chunks = parse_bedrock_stream(data)
                if not chunks or #chunks == 0 then return { status = STATUS_SUCCESS, output = output } end

                for _, message in ipairs(chunks) do
                  local part = anthropic.handlers.chat_output(self, message, tools)
                  if not part then goto continue end

                  -- Handle error status
                  if part.status ~= STATUS_SUCCESS then return { status = part.status, output = output } end

                  -- Merge successful response data
                  if part.output then
                    output.role = output.role or part.output.role
                    output.reasoning = merge_reasoning(output.reasoning, part.output.reasoning)
                    output.content = merge_content(output.content, part.output.content)
                  end

                  ::continue::
                end
                return {
                  status = STATUS_SUCCESS,
                  output = output,
                }
              end,
            },
            schema = {
              model = {
                mapping = 'temp',
                default = 'us.anthropic.claude-3-7-sonnet-20250219-v1:0',
                choices = {
                  ['us.anthropic.claude-sonnet-4-20250514-v1:0'] = { opts = { can_reason = true, has_vision = true } },
                  ['us.anthropic.claude-3-7-sonnet-20250219-v1:0'] = { opts = { can_reason = true, has_vision = true } },
                },
              },
              region = {
                type = 'string',
                default = 'us-west-2',
                desc = 'AWS region',
                choices = {
                  'us-east-1',
                  'us-east-2',
                  'us-west-1',
                  'us-west-2',
                },
              },
              anthropic_version = {
                mapping = 'parameters',
                type = 'string',
                optional = false,
                default = 'bedrock-2023-05-31',
                desc = 'Bedrock anthropic API version',
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
      },
      strategies = {
        chat = {
          adapter = "bedrock",
          -- adapter = {
          --   name = "anthropic",
          --   model = "claude-sonnet-4-20250514",
          -- },
          -- roles = {
          --   user = "olimorris",
          -- },
        },
        inline = {
          adapter = {
            name = "bedrock",
            -- model = "gpt-4.1",
          },
        },
      },
      display = {
        action_palette = {
          provider = "default",
          opts = {
            show_default_actions = true, -- Show the default actions in the action palette?
            show_default_prompt_library = true, -- Show the default prompt library in the action palette?
          },
        },
        chat = {
          -- show_references = true,
          -- show_header_separator = false,
          -- show_settings = false,
          auto_scroll = true,
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
}
