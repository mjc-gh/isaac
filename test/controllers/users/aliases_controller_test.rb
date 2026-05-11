# frozen_string_literal: true

require "test_helper"

class Users::AliasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @alias = user_aliases(:alice_alias_1)
    @bob_alias = user_aliases(:bob_alias)
  end

  test "index requires authentication" do
    get users_aliases_url

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.unauthenticated"), flash[:alert]
  end

  test "index displays user aliases when authenticated" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get users_aliases_url

    assert_response :success
    assert_select "h1", "Manage Aliases"
    assert_select "table tbody tr", count: 2
    assert_select "table tbody tr td", text: @alias.email
  end

  test "new requires authentication" do
    get new_users_alias_url

    assert_redirected_to new_users_session_url
    assert_match I18n.t("sessions.unauthenticated"), flash[:alert]
  end

  test "new renders form when authenticated" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get new_users_alias_url

    assert_response :success
    assert_select "form input[type=email]"
  end

  test "create creates alias for current user" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    assert_difference("UserAlias.count", 1) do
      post users_aliases_url, params: { user_alias: { email: "newalias@example.com" } }
    end

    assert_redirected_to users_aliases_url
    assert_match I18n.t("aliases.created"), flash[:notice]
    assert_equal "newalias@example.com", @user.user_aliases.last.email
  end

  test "create with invalid params re-renders form" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    post users_aliases_url, params: { user_alias: { email: "invalid-email" } }

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "create with duplicate email fails" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    post users_aliases_url, params: { user_alias: { email: @alias.email } }

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "edit renders form for user's alias" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get edit_users_alias_url(@alias)

    assert_response :success
    assert_select "form input[type=email][value=?]", @alias.email
  end

  test "user cannot edit another user's alias" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    get edit_users_alias_url(@bob_alias)

    assert_response :not_found
  end

  test "update updates alias successfully" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    patch users_alias_url(@alias), params: { user_alias: { email: "updated@example.com" } }

    assert_redirected_to users_aliases_url
    assert_match I18n.t("aliases.updated"), flash[:notice]
    @alias.reload
    assert_equal "updated@example.com", @alias.email
  end

  test "update with invalid params re-renders form" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    patch users_alias_url(@alias), params: { user_alias: { email: "invalid-email" } }

    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "destroy removes alias" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    assert_difference("UserAlias.count", -1) do
      delete users_alias_url(@alias)
    end

    assert_redirected_to users_aliases_url
    assert_match I18n.t("aliases.destroyed"), flash[:notice]
  end

  test "user cannot delete another user's alias" do
    post users_sessions_url, params: { email: @user.email }
    token = @user.generate_magic_link_token(for: :session)
    get verify_users_sessions_url(token: token)

    delete users_alias_url(@bob_alias)

    assert_response :not_found
  end
end
