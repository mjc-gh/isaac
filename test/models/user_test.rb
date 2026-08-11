# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user creation" do
    user = User.new(email: "test@example.com", first_name: "Test", last_name: "User")
    assert user.valid?
  end

  test "email address normalization" do
    user = User.create!(email: "TEST@EXAMPLE.COM", first_name: "Test", last_name: "User")
    assert_equal "test@example.com", user.email
  end

  test "email uniqueness validation case insensitive" do
    User.create!(email: "unique@example.com", first_name: "First", last_name: "User")
    user = User.new(email: "UNIQUE@EXAMPLE.COM", first_name: "Second", last_name: "User")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "blank email bypasses alias check validation" do
    user = User.new(email: "", first_name: "Test", last_name: "User")
    assert_not user.valid?
    # Should fail on email presence/format, not alias check
    assert user.errors[:email].any?
  end

  test "primary_calendar_id accessor" do
    user = users(:alice)
    user.primary_calendar_id = "calendar_123"
    assert_equal "calendar_123", user.primary_calendar_id
  end

  test "primary_calendar_id returns nil when not set" do
    user = User.create!(email: "test@example.com", first_name: "Test", last_name: "User")
    assert_nil user.primary_calendar_id
  end

  test "timezone defaults to UTC" do
    user = User.create!(email: "test@example.com", first_name: "Test", last_name: "User")
    assert_equal "UTC", user.timezone
  end

  test "timezone must be a recognized time zone" do
    user = User.new(email: "test@example.com", first_name: "Test", last_name: "User", timezone: "Not/A_Timezone")
    assert_not user.valid?
    assert_includes user.errors[:timezone], "is not included in the list"
  end
end
