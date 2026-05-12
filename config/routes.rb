# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  resources :dashboards, only: [:index]

  namespace :users do
    resources :sessions, only: [:new, :create, :destroy] do
      collection { get :verify }
    end

    resources :aliases
    resources :auth_tokens, only: [:index, :destroy]
  end

  get "auth/failure", to: "users/oauth_callbacks#failure", as: :users_auth_failure
  get "auth/:provider/callback", to: "users/oauth_callbacks#create", as: :users_oauth

  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
