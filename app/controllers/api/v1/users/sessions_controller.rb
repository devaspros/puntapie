module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        skip_before_action :verify_authenticity_token, only: [:create]

        # POST /api/v1/users/sign_in
        def create
          user = User.find_by(email: params[:email])

          if user&.valid_password?(params[:password])
            token = JsonWebToken.encode(payload: { user_id: user.id })

            render json: { token: token, user: { id: user.id, email: user.email } }, status: :created
          else
            render json: { error: "Invalid email or password" }, status: :unauthorized
          end
        end
      end
    end
  end
end
