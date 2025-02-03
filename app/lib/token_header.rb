class TokenHeader
  attr_reader :payload

  def initialize(header)
    @header = header.to_s
    @payload = decode_token
  end

  def token?
    @header.start_with?("Token")
  end

  def extract_token
    @header.delete_prefix("Token").lstrip
  end

  def valid_token?(field, assertion_text)
    return false if @payload.nil?

    @payload.first[field] == assertion_text
  end

  def user_id
    @payload.first.fetch("user_id")
  end

  private

  def decode_token
    JsonWebToken.decode(token: extract_token)
  rescue JWT::DecodeError
    nil
  end
end
