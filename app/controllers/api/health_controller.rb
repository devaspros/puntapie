module Api
  class HealthController < ActionController::Base
    def show
      head :ok
    end
  end
end
