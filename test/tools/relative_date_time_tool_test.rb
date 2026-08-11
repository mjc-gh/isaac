# frozen_string_literal: true

require "test_helper"

class RelativeDateTimeToolTest < ActiveSupport::TestCase
  setup do
    @tool = RelativeDateTimeTool.new(users(:alice))
  end

  test "converts a relative time to ISO8601" do
    parsed_time = Time.zone.parse("2026-07-27 12:00:00")

    Chronic.stub :parse, parsed_time do
      assert_equal parsed_time.iso8601, @tool.execute(relative_time: "noon")
    end
  end

  test "returns an error for an invalid relative time" do
    Chronic.stub :parse, nil do
      assert_equal({ error: "Invalid relative_time" }, @tool.execute(relative_time: "not a time"))
    end
  end
end
