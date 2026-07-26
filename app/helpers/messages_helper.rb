# frozen_string_literal: true

module MessagesHelper
  def format_tool_value(value)
    parsed_value = value.is_a?(String) ? JSON.parse(value) : value
    return parsed_value if parsed_value.is_a?(String)

    JSON.pretty_generate(parsed_value)
  rescue JSON::ParserError
    value
  end
end
