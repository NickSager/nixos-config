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
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "j-hui/fidget.nvim", -- Display status
      {
        "nvim-mini/mini.diff",
        config = function()
          require("mini.diff").setup({
            source = require("mini.diff").gen_source.none(),
          })
        end,
      },
    },
    opts = {
      ---@module "codecompanion"
      ---@type CodeCompanion.Config
      adapters = {
        acp = {
          claude_code = function()
            -- Read Claude Code settings.json to get Bedrock config
            local settings_file = vim.fn.expand("~/.claude/settings.json")
            local settings = {}

            if vim.fn.filereadable(settings_file) == 1 then
              local ok, decoded = pcall(vim.fn.json_decode, vim.fn.readfile(settings_file))
              if ok and decoded.env then
                settings = decoded.env
              end
            end

            return require("codecompanion.adapters.acp").extend("claude_code", {
              commands = {
                default = {
                  "npx",
                  "--yes",
                  "@zed-industries/claude-code-acp",
                },
              },
              env = {
                -- Use AWS Bedrock (from settings.json or default to 1)
                CLAUDE_CODE_USE_BEDROCK = settings.CLAUDE_CODE_USE_BEDROCK or "1",
                AWS_PROFILE = settings.AWS_PROFILE or "claude",
                AWS_REGION = settings.AWS_REGION or "us-west-2",
                -- Pass through any other settings from settings.json
                ANTHROPIC_DEFAULT_SONNET_MODEL = settings.ANTHROPIC_DEFAULT_SONNET_MODEL,
                ANTHROPIC_DEFAULT_OPUS_MODEL = settings.ANTHROPIC_DEFAULT_OPUS_MODEL,
                ANTHROPIC_DEFAULT_HAIKU_MODEL = settings.ANTHROPIC_DEFAULT_HAIKU_MODEL,
              },
              handlers = {
                setup = function(self)
                  -- Refresh AWS credentials before starting ACP session
                  local isengard_acct = os.getenv("ISENGARD_ACCT")
                  if isengard_acct and isengard_acct ~= "" then
                    local refresh_cmd = string.format(
                      "ada credentials update --profile claude --account %s --provider isengard --role Admin --once",
                      isengard_acct
                    )
                    vim.fn.system(refresh_cmd)
                  end
                  return true
                end,
              },
            })
          end,
        },
        http = {
          anthropic = function()
            return require("codecompanion.adapters.http").extend("anthropic", {
              schema = {
                extended_thinking = {
                  default = true,
                },
              },
            })
          end,

          bedrock = function()
            local anthropic = require 'codecompanion.adapters.http.anthropic'

            ---@class Bedrock.Adapter: CodeCompanion.Adapter
            return require('codecompanion.adapters.http').extend('anthropic', {
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
                  default = 'us.anthropic.claude-sonnet-4-5-20250929-v1:0',
                  choices = {
                    ['us.anthropic.claude-opus-4-5-20251101-v1:0'] = { opts = { can_reason = true, has_vision = true } },
                    ['us.anthropic.claude-sonnet-4-5-20250929-v1:0'] = { opts = { can_reason = true, has_vision = true } },
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
            return require("codecompanion.adapters.http").extend("ollama", {
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
      },
      interactions = {
        chat = {
          adapter = "claude_code",
        },
        inline = {
          adapter = "bedrock",
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
        log_level = "INFO",
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
      {
        "<Leader>ac",
        "<cmd>CodeCompanionChat adapter=claude_code<CR>",
        desc = "Chat with Claude Code (ACP)",
        mode = { "n", "v" },
      },
      {
        "<Leader>ab",
        "<cmd>CodeCompanionChat adapter=bedrock<CR>",
        desc = "Chat with Bedrock (HTTP)",
        mode = { "n", "v" },
      },
    },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      -- require("plugins.custom.spinner"):init()
    end,
  },
}
