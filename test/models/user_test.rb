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
end
