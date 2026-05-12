# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :require_authentication

  def index
    @auth_tokens_count = current_user.auth_tokens.count
  end
end
