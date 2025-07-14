local log = require("codecompanion.utils.log")
local tokens = require("codecompanion.utils.tokens")
local transform = require("codecompanion.utils.tool_transformers")
local utils = require("codecompanion.utils.adapters")

local input_tokens = 0
local output_tokens = 0

---Remove any keys from the message that are not allowed by the API
---@param message table The message to filter
---@return table The filtered message
local function filter_out_messages(message)
  local allowed = {
    "content",
    "role",
    "reasoning",
    "tool_calls",
  }

  for key, _ in pairs(message) do
    if not vim.tbl_contains(allowed, key) then
      message[key] = nil
    end
  end
  return message
end

---@class Bedrock.Adapter: CodeCompanion.Adapter
return {
  name = "bedrock",
  formatted_name = "AWS Bedrock",
  roles = {
    llm = "assistant",
    user = "user",
  },
  features = {
    tokens = true,
    text = true,
  },
  opts = {
    stream = true,
    tools = true,
    vision = true,
  },
  env = {
    region = "AWS_DEFAULT_REGION", -- e.g., "us-east-1"
    model = "schema.model.default",
  },
  headers = {
    ["content-type"] = "application/json",
    ["accept"] = "application/vnd.amazon.eventstream",
  },
  raw = {
    ["--aws-sigv4"] = "aws:amz:${region}:bedrock"
  },
  temp = {},
  handlers = {
    ---@param self CodeCompanion.Adapter
    ---@return boolean
    setup = function(self)
      -- Set the URL dynamically in setup
      if self.opts and self.opts.stream then
        self.parameters.stream = true
        self.url = "https://bedrock-runtime.${region}.amazonaws.com/model/${model}/invoke-with-response-stream"
      else
        self.url = "https://bedrock-runtime.${region}.amazonaws.com/model/${model}/invoke"
        self.headers["accept"] = "application/json"
      end


      -- Make sure the individual model options are set
      local model = self.schema.model.default
      local model_opts = self.schema.model.choices[model]
      if model_opts and model_opts.opts then
        self.opts = vim.tbl_deep_extend("force", self.opts, model_opts.opts)
        if not model_opts.opts.has_vision then
          self.opts.vision = false
        end
      end

      return true
    end,

    ---Set the parameters
    ---@param self CodeCompanion.Adapter
    ---@param params table
    ---@param messages table
    ---@return table
    form_parameters = function(self, params, messages)
      return params
    end,

    ---Set the format of the role and content for the messages that are sent from the chat buffer to the LLM
    ---@param self CodeCompanion.Adapter
    ---@param messages table Format is: { { role = "user", content = "Your prompt here" } }
    ---@return table
    form_messages = function(self, messages)
      -- Bedrock uses the same Anthropic Claude format
      -- Extract system message
      local system_message = ""
      local filtered_messages = {}
      
      for _, message in ipairs(messages) do
        if message.role == "system" then
          system_message = message.content
        else
          -- Convert content to Anthropic format if needed
          if type(message.content) == "string" then
            message.content = {
              { type = "text", text = message.content }
            }
          end
          table.insert(filtered_messages, message)
        end
      end
      
      -- Return in Bedrock Claude format
      return {
        anthropic_version = "bedrock-2023-05-31",
        system = system_message ~= "" and system_message or nil,
        messages = filtered_messages,
      }
    end,

    ---Returns the number of tokens generated from the LLM
    ---@param self CodeCompanion.Adapter
    ---@param data table The data from the LLM
    ---@return number|nil
    tokens = function(self, data)
      if data then
        if self.opts.stream then
          data = utils.clean_streamed_data(data)
        else
          data = data.body
        end
        local ok, json = pcall(vim.json.decode, data)

        if ok then
          if json.type == "message_start" then
            input_tokens = (json.message.usage.input_tokens or 0)
              + (json.message.usage.cache_creation_input_tokens or 0)
            output_tokens = json.message.usage.output_tokens or 0
          elseif json.type == "message_delta" then
            return (input_tokens + output_tokens + json.usage.output_tokens)
          elseif json.type == "message" then
            return (json.usage.input_tokens + json.usage.output_tokens)
          elseif json.usage then
            -- Fallback for non-streaming
            return (json.usage.input_tokens or 0) + (json.usage.output_tokens or 0)
          end
        end
      end
    end,

    ---Output the data from the API ready for insertion into the chat buffer
    ---@param self CodeCompanion.Adapter
    ---@param data table The streamed JSON data from the API, also formatted by the format_data handler
    ---@param tools? table The table to write any tool output to
    ---@return table|nil [status: string, output: table]
    chat_output = function(self, data, tools)
      local output = {}

      if self.opts.stream then
        if type(data) == "string" and string.sub(data, 1, 6) == "event:" then
          return
        end
      end

      if data and data ~= "" then
        if self.opts.stream then
          data = utils.clean_streamed_data(data)
        else
          data = data.body
        end

        local ok, json = pcall(vim.json.decode, data, { luanil = { object = true } })

        if ok then
          if json.type == "message_start" then
            output.role = json.message.role
            output.content = ""
          elseif json.type == "content_block_start" then
            if json.content_block.type == "thinking" then
              output.reasoning = output.reasoning or {}
              output.reasoning.content = ""
            end
            if json.content_block.type == "tool_use" and tools then
              table.insert(tools, {
                _index = json.index,
                id = json.content_block.id,
                name = json.content_block.name,
                input = "",
              })
            end
          elseif json.type == "content_block_delta" then
            if json.delta.type == "thinking_delta" then
              output.reasoning = output.reasoning or {}
              output.reasoning.content = json.delta.thinking
            elseif json.delta.type == "signature_delta" then
              output.reasoning = output.reasoning or {}
              output.reasoning.signature = json.delta.signature
            else
              output.content = json.delta.text
              if json.delta.partial_json and tools then
                for i, tool in ipairs(tools) do
                  if tool._index == json.index then
                    tools[i].input = tools[i].input .. json.delta.partial_json
                    break
                  end
                end
              end
            end
          elseif json.type == "message" then
            output.role = json.role

            for i, content in ipairs(json.content) do
              if content.type == "text" then
                output.content = (output.content or "") .. content.text
              elseif content.type == "thinking" then
                output.reasoning = output.reasoning and output.reasoning or {}
                output.reasoning.content = content.text
              elseif content.type == "tool_use" and tools then
                table.insert(tools, {
                  _index = i,
                  id = content.id,
                  name = content.name,
                  input = vim.json.encode(content.input),
                })
              end
            end
          else
            -- Handle non-streaming response format
            output.role = json.role or "assistant"
            output.content = ""
            
            if json.content and type(json.content) == "table" then
              for _, content_block in ipairs(json.content) do
                if content_block.type == "text" then
                  output.content = output.content .. content_block.text
                end
              end
            end
          end

          return {
            status = "success",
            output = output,
          }
        end
      end
    end,

    ---Output the data from the API ready for inlining into the current buffer
    ---@param self CodeCompanion.Adapter
    ---@param data table The streamed JSON data from the API, also formatted by the format_data handler
    ---@param context? table Useful context about the buffer to inline to
    ---@return table|nil
    inline_output = function(self, data, context)
      if self.opts.stream then
        return log:error("Inline output is not supported for streaming models")
      end

      if data and data ~= "" then
        local ok, json = pcall(vim.json.decode, data.body, { luanil = { object = true } })

        if not ok then
          log:error("Error decoding JSON: %s", data.body)
          return { status = "error", output = json }
        end

        if ok then
          if json.content and json.content[1] and json.content[1].text then
            return { status = "success", output = json.content[1].text }
          end
        end
      end
    end,

    ---Function to run when the request has completed. Useful to catch errors
    ---@param self CodeCompanion.Adapter
    ---@param data? table
    ---@return nil
    on_exit = function(self, data)
      if data and data.status >= 400 then
        log:error("Error %s: %s", data.status, data.body)
      end
    end,
  },
  schema = {
    ---@type CodeCompanion.Schema
    model = {
      order = 1,
      mapping = "parameters",
      type = "enum",
      desc = "The model that will complete your prompt. See AWS Bedrock documentation for available models.",
      default = "anthropic.claude-3-5-sonnet-20241022-v2:0",
      choices = {
        -- Claude 3.5 Models (Latest)
        ["anthropic.claude-3-5-sonnet-20241022-v2:0"] = { opts = { has_vision = true } },
        ["anthropic.claude-3-5-haiku-20241022-v1:0"] = { opts = { has_vision = true } },
        -- Claude 3 Models
        ["anthropic.claude-3-opus-20240229-v1:0"] = { opts = { has_vision = true } },
        ["anthropic.claude-3-sonnet-20240229-v1:0"] = { opts = { has_vision = true } },
        ["anthropic.claude-3-haiku-20240307-v1:0"] = { opts = { has_vision = true } },
        -- Legacy Claude Models
        ["anthropic.claude-instant-v1"] = { opts = {} },
        ["anthropic.claude-v2:1"] = {},
        ["anthropic.claude-v2"] = {},
        -- Additional Claude 3.5 variants
        ["anthropic.claude-3-5-sonnet-20240620-v1:0"] = { opts = { has_vision = true } },
      },
    },
    ---@type CodeCompanion.Schema
    max_tokens = {
      order = 2,
      mapping = "parameters",
      type = "number",
      optional = true,
      default = 4096,
      desc = "The maximum number of tokens to generate before stopping.",
      validate = function(n)
        return n > 0 and n <= 128000, "Must be between 0 and 128000"
      end,
    },
    ---@type CodeCompanion.Schema
    temperature = {
      order = 3,
      mapping = "parameters",
      type = "number",
      optional = true,
      default = 0,
      desc = "Amount of randomness injected into the response. Ranges from 0.0 to 1.0.",
      validate = function(n)
        return n >= 0 and n <= 1, "Must be between 0 and 1.0"
      end,
    },
    ---@type CodeCompanion.Schema
    top_p = {
      order = 4,
      mapping = "parameters",
      type = "number",
      optional = true,
      default = nil,
      desc = "Computes the cumulative distribution over all the options for each subsequent token",
      validate = function(n)
        return n >= 0 and n <= 1, "Must be between 0 and 1"
      end,
    },
    ---@type CodeCompanion.Schema
    top_k = {
      order = 5,
      mapping = "parameters",
      type = "number",
      optional = true,
      default = nil,
      desc = "Only sample from the top K options for each subsequent token",
      validate = function(n)
        return n >= 0, "Must be greater than 0"
      end,
    },
    ---@type CodeCompanion.Schema
    stop_sequences = {
      order = 6,
      mapping = "parameters",
      type = "list",
      optional = true,
      default = nil,
      subtype = {
        type = "string",
      },
      desc = "Sequences where the API will stop generating further tokens",
      validate = function(l)
        return #l >= 1, "Must have more than 1 element"
      end,
    },
  },
}