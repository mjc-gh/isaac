# frozen_string_literal: true

require "test_helper"

class AuthTokenTest < ActiveSupport::TestCase
  test "valid auth token creation" do
    user = users(:alice)
    auth_token = AuthToken.new(user:, provider: "slack", access_token: "token123", scopes: ["chat:write"], expires_at: 1.day.from_now)
    assert auth_token.valid?
  end

  test "provider presence validation" do
    user = users(:alice)
    auth_token = AuthToken.new(user:, provider: "", access_token: "token123", expires_at: 1.day.from_now)
    assert_not auth_token.valid?
    assert auth_token.errors[:provider].any?
  end

  test "access token presence validation" do
    user = users(:alice)
    auth_token = AuthToken.new(user:, provider: "github", access_token: "", expires_at: 1.day.from_now)
    assert_not auth_token.valid?
    assert auth_token.errors[:access_token].any?
  end

  test "uniqueness of provider per user" do
    user_a = users(:alice)
    AuthToken.create!(user: user_a, provider: "slack", access_token: "token_a", scopes: ["chat:write"], expires_at: 1.day.from_now)

    auth_token = AuthToken.new(user: user_a, provider: "slack", access_token: "token_b", scopes: ["chat:read"], expires_at: 1.day.from_now)
    assert_not auth_token.valid?
    assert auth_token.errors[:provider].any?
  end

  test "same provider allowed for different users" do
    user_a = users(:alice)
    user_b = users(:bob)
    AuthToken.create!(user: user_a, provider: "slack", access_token: "token_a", scopes: ["chat:write"], expires_at: 1.day.from_now)
    auth_token = AuthToken.new(user: user_b, provider: "slack", access_token: "token_b", scopes: ["chat:read"], expires_at: 1.day.from_now)
    assert auth_token.valid?
  end

  test "auth token belongs to user" do
    auth_token = auth_tokens(:alice_google)
    assert_equal users(:alice), auth_token.user
  end

  test "user has many auth tokens" do
    user = users(:alice)
    auth_token = AuthToken.create!(user:, provider: "slack", access_token: "token123", scopes: ["chat:write"], expires_at: 1.day.from_now)
    assert user.auth_tokens.include?(auth_token)
  end

  test "destroying user destroys auth tokens" do
    user = users(:alice)
    user_id = user.id
    token_count_before = AuthToken.where(user_id:).count

    assert token_count_before > 0

    user.destroy
    assert_equal 0, AuthToken.where(user_id:).count
  end

  test "access token encryption" do
    user = users(:alice)
    access_token_value = "secret_access_token"
    auth_token = AuthToken.create!(user:, provider: "github", access_token: access_token_value, scopes: ["repo"], expires_at: 1.day.from_now)

    fetched = AuthToken.find(auth_token.id)
    assert_equal access_token_value, fetched.access_token
  end

  test "refresh token encryption" do
    user = users(:alice)
    refresh_token_value = "secret_refresh_token"
    auth_token = AuthToken.create!(user:, provider: "github", access_token: "access", refresh_token: refresh_token_value, scopes: ["repo"], expires_at: 1.day.from_now)

    fetched = AuthToken.find(auth_token.id)
    assert_equal refresh_token_value, fetched.refresh_token
  end
end
