# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :require_authentication

  def index
    @aliases_count = current_user.user_aliases.count
    @auth_tokens_count = current_user.auth_tokens.count
  end
end
