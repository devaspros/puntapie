# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout

  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  # La página "Mi cuenta" se muestra dentro del panel; el registro, con el layout de login.
  def resolve_layout
    %w[edit update].include?(action_name) ? "application" : "login"
  end

  def after_update_path_for(_resource)
    edit_user_registration_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end
end
