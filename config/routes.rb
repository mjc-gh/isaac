Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  resources :dashboards, only: [:index]

  namespace :users do
    resources :sessions, only: [:new, :create, :destroy] do
      collection { get :verify }
    end
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
