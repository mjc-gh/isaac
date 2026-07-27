# frozen_string_literal: true

require "test_helper"

class MessagesHelperTest < ActiveSupport::TestCase
  include MessagesHelper

  test "pretty prints JSON strings" do
    assert_equal "{\n  \"name\": \"ISAAC\"\n}", format_tool_value('{"name":"ISAAC"}')
  end

  test "pretty prints non-string values" do
    assert_equal "[\n  1,\n  2\n]", format_tool_value([1, 2])
  end

  test "returns JSON string values without pretty printing" do
    assert_equal "ISAAC", format_tool_value('"ISAAC"')
  end

  test "returns invalid JSON unchanged" do
    value = "not JSON"

    assert_equal value, format_tool_value(value)
  end
end
