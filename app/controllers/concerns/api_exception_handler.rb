module ApiExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordNotUnique, with: :not_unique
    rescue_from ActionController::ParameterMissing, with: :missing_parameter
  end

  private

  def not_found(exception)
    render json: { errors: "#{exception.model} does not exist" }, status: :not_found
  end

  def not_unique(exception)
    error_message = if exception.to_s.include?("email")
                      "Email has already been taken"
                    else
                      "¯\_(ツ)_/¯"
                    end

    render json: { errors: error_message }, status: :unprocessable_entity
  end

  def missing_parameter(exception)
    render json: { errors: exception.message },
           status: :unprocessable_entity
  end
end
