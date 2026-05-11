# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to dashboards_url
    else
      redirect_to new_users_session_path
    end
  end
end
