class Rack::Attack
  throttle("sign_up/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/users"
  end

  throttle("sign_up/email", limit: 3, period: 1.hour) do |req|
    if req.post? && req.path == "/users"
      req.params["user"]&.[]("email")&.downcase
    end
  end
end
