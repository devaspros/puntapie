class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery with: :exception

  before_action :authenticate_user!

  layout :layout_by_resource

  private

  def layout_by_resource
    if devise_controller?
      "login"
    else
      "application"
    end
  end
end
