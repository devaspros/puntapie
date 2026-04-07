require "sidekiq/web"

Rails.application.routes.draw do
  root to: "home#index"

  get "/dashboard", to: "dashboard#index", as: :dashboard
  get "/privacy-policy", to: "home#privacy", as: :privacy_policy
  get "/tos", to: "home#tos", as: :tos

  devise_for(
    :users,
    controllers: {
      registrations: "users/registrations"
    }
  )

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"

    namespace :admin do
    end
  end

  namespace "api", default: { format: "json" } do
    namespace :v1 do
      devise_for :users, controllers: {
        sessions: "api/v1/users/sessions"
      }
    end
  end
end
