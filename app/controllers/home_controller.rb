# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    render status: 404, plain: "Not Found"
  end
end
