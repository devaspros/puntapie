class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  layout "landing"

  def index
    # redirect_to dashboard_path if current_user.present?
  end

  def privacy; end

  def tos; end
end
