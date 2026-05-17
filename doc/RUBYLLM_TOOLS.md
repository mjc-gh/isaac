# RubyLLM Tools Guide

RubyLLM provides a framework for creating tools that AI agents can use to perform actions. This document covers the patterns and conventions used in the isaac project.

## Overview

Tools are classes that inherit from `RubyLLM::Tool` and define specific actions the AI can take. Tools are bound to agents and called by the LLM based on the conversation context.

## Tool Structure

### Basic Template

```ruby
# frozen_string_literal: true

class MyActionTool < RubyLLM::Tool
  description "Clear description of what this tool does"

  param :param_name, type: "string", desc: "Parameter description", required: true
  param :optional_param, type: "string", desc: "Optional parameter", required: false

  def initialize(dependency)
    @dependency = dependency
  end

  def execute(param_name:, optional_param: nil)
    # Implementation here
    "result as string or JSON"
  rescue StandardError => e
    { error: e.message }
  end
end
```

### Key Components

**Description**: Set with the `description` method (or `desc` alias). This is shown to the LLM and helps it understand when to use the tool.

**Parameters**: Define with `param` DSL with options:
- `type`: One of `'string'`, `'integer'`, `'number'`, `'boolean'`, `'array'`, `'object'` (default: `'string'`)
- `desc` or `description`: Parameter help text for the LLM
- `required`: Boolean (default: `true`)

**Constructor**: Accepts dependencies (e.g., user object) to be used in the execute method.

**Execute Method**: 
- Must be implemented by subclasses
- Signature must use keyword arguments matching defined parameters
- Return value is passed to the LLM (string or JSON-serializable object)
- Return `{ error: "message" }` for errors
- Can raise custom exceptions (will be caught and reported to user)

## Tool Naming

Tool names are automatically derived from the class name:
- `GoogleCalendarSearchTool` → `google_calendar_search`
- `SendEmailTool` → `send_email`
- Suffix `_tool` is automatically removed

## Parameter Types

RubyLLM converts parameter types to JSON schema:
- `'string'` → JSON `"string"`
- `'integer'` or `'int'` → JSON `"integer"`
- `'number'`, `'float'`, `'double'` → JSON `"number"`
- `'boolean'` → JSON `"boolean"`
- `'array'` → JSON `"array"` (with string items by default)
- `'object'` → JSON `"object"`

## Tool Execution Flow

1. LLM determines when to use a tool based on description and conversation context
2. LLM generates tool call with parameters as JSON
3. RubyLLM framework:
   - Validates parameters against defined schema
   - Normalizes arguments to symbols
   - Calls `execute(**normalized_args)`
4. Tool result is returned to LLM for further processing

## Binding Tools to Agents

### Method 1: Agent-Level Binding (Recommended for simple cases)

Define tools in the agent class using the `tools` DSL:

```ruby
class MyAgent < RubyLLM::Agent
  chat_model Chat
  model "google/gemini-2.5-flash-lite"

  # Static tools
  tools MyActionTool.new

  # Dynamic tools (with access to chat context)
  tools -> { [ContextualTool.new(chat.user)] }
end
```

The `tools` DSL accepts:
- Direct tool instances: `tools MyTool.new`
- Procs/lambdas that return tool arrays: `tools -> { [MyTool.new(chat.user)] }`
- Multiple tools: `tools Tool1.new, Tool2.new, -> { [Tool3.new] }`

### Method 2: Mailbox-Level Binding (For user context)

Bind tools in the mailbox after creating the chat:

```ruby
class AssistantMailbox < ApplicationMailbox
  def process
    email = mail.from_address.try(:address)
    user = find_user_by_email(email)

    chat = AssistantAgent.create!(user:, forwarded_message: nil)
    chat.with_tool(GoogleCalendarSearchTool.new(user))

    response = chat.ask(mail.body.decoded)
    # ...
  end
end
```

The `chat.with_tool()` method:
- Takes a tool instance
- Adds it to the chat's available tools
- Can be called multiple times to add multiple tools

## Error Handling

### Tool-Level Errors

Return error objects from execute:

```ruby
def execute(param:)
  service.do_something(param)
rescue ServiceError => e
  { error: "Service unavailable: #{e.message}" }
end
```

### Token/Auth Errors

Custom exception classes should be raised; the framework catches them:

```ruby
def execute(param:)
  service = GoogleCalendarService.new(@user)
  service.list_events(...)
rescue GoogleCalendarTokenError => e
  { error: e.message }
end
```

## Parameter Parsing

The LLM passes parameters as strings. Tools must parse them:

**ISO8601 DateTime strings:**
```ruby
param :start_time, type: "string", desc: "Start time in ISO8601 format"

def execute(start_time:)
  time = Time.parse(start_time)  # Parse to Time object
  # Use time...
end
```

**JSON strings:**
```ruby
param :data, type: "string", desc: "JSON data"

def execute(data:)
  parsed = JSON.parse(data)
  # Use parsed...
end
```

## Testing Tools

### Test Setup

Use Minitest with mocks for external dependencies:

```ruby
require "test_helper"

class MyToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @tool = MyTool.new(@user)
  end

  test "tool has correct name" do
    assert_equal "my_tool", @tool.name
  end

  test "tool has description" do
    assert @tool.description.present?
  end

  test "execute returns expected result" do
    result = @tool.execute(param: "value")
    assert_equal "expected", result
  end
end
```

## File Organization

Tools follow these conventions:
- Location: `app/tools/`
- Naming: `*_tool.rb` (e.g., `google_calendar_search_tool.rb`)
- Tests: `test/tools/*_tool_test.rb`
- One class per file
- Frozen string literal at top of file
