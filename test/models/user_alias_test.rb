# frozen_string_literal: true

require "test_helper"

class UserAliasTest < ActiveSupport::TestCase
  test "valid user alias creation" do
    user = users(:alice)
    alias_email = "alice.secondary@example.com"
    user_alias = UserAlias.new(user:, email: alias_email)
    assert user_alias.valid?
  end

  test "email address normalization" do
    user = users(:alice)
    user_alias = UserAlias.create!(user:, email: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", user_alias.email
  end

  test "email presence validation" do
    user = users(:alice)
    user_alias = UserAlias.new(user:, email: "")
    assert_not user_alias.valid?
    assert user_alias.errors[:email].any?
  end

  test "email uniqueness validation case insensitive" do
    user_a = users(:alice)
    user_b = users(:bob)
    UserAlias.create!(user: user_a, email: "shared@example.com")

    user_alias = UserAlias.new(user: user_b, email: "SHARED@EXAMPLE.COM")
    assert_not user_alias.valid?
    assert user_alias.errors[:email].any?
  end

  test "email format validation" do
    user = users(:alice)
    user_alias = UserAlias.new(user:, email: "invalid-email")
    assert_not user_alias.valid?
    assert user_alias.errors[:email].any?
  end

  test "email cannot conflict with user primary email" do
    user = users(:alice)
    alice_primary_email = user.email

    user_alias = UserAlias.new(user: users(:bob), email: alice_primary_email)
    assert_not user_alias.valid?
    assert user_alias.errors[:email].any?
  end

  test "user cannot set email that conflicts with alias" do
    user_a = users(:alice)
    user_b = users(:bob)
    conflicting_email = "conflict@example.com"

    UserAlias.create!(user: user_a, email: conflicting_email)

    user_b.email = conflicting_email
    assert_not user_b.valid?
    assert user_b.errors[:email].any?
  end

  test "user alias belongs to user" do
    user_alias = user_aliases(:alice_alias_1)
    assert_equal users(:alice), user_alias.user
  end

  test "user has many aliases" do
    user = users(:alice)
    assert_equal 2, user.user_aliases.count
  end

  test "destroying user destroys aliases" do
    user = users(:alice)
    user_id = user.id
    alias_count_before = UserAlias.where(user_id:).count

    assert alias_count_before > 0

    user.destroy
    assert_equal 0, UserAlias.where(user_id:).count
  end
end
