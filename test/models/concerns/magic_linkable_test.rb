# frozen_string_literal: true

require "test_helper"

class MagicLinkableTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "generates a valid magic link token" do
    token = @user.generate_magic_link_token(for: :session)
    assert_not_nil token
    assert_instance_of String, token
  end

  test "finds user by valid magic link token" do
    token = @user.generate_magic_link_token(for: :session)
    found_user = User.find_by_magic_link_token(token, for: :session)
    assert_equal @user, found_user
  end

  test "returns nil for invalid magic link token" do
    found_user = User.find_by_magic_link_token("invalid_token", for: :session)
    assert_nil found_user
  end

  test "returns nil for expired magic link token" do
    token = @user.generate_magic_link_token(expires_in: -1.second, for: :session)
    found_user = User.find_by_magic_link_token(token, for: :session)
    assert_nil found_user
  end

  test "token purpose scoping prevents replay attacks" do
    token = @user.generate_magic_link_token(for: :session)
    found_user = User.find_by_magic_link_token(token, for: :different_purpose)
    assert_nil found_user
  end
end
