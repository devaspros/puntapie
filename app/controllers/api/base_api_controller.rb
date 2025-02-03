module Api
  # Esta clase se encarga de toda la gestión global de los controladores
  # de la API en cualquier versión.
  #
  # Nota que no hereda de ApplicationController. Ese controlador queda para controladores
  # que interactuen con vistas.
  class BaseApiController < ActionController::Base
    protect_from_forgery with: :null_session

    before_action :authenticate_with_access_token!

    include ApiExceptionHandler

    private

    def authenticate_with_access_token!
      header = TokenHeader.new(request.headers["Authorization"])

      if header.token?
        head :forbidden unless header.valid_token?("iss", JsonWebToken::ISSUER)

        @current_user = User.find(header.user_id)
      else
        head :forbidden
      end
    end

    def current_user
      @current_user
    end
  end
end
