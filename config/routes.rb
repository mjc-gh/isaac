Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
