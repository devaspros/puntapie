module JsonWebToken
  JWT_SECRET = ENV["JWT_SECRET"] || ENV["SECRET_KEY_BASE"]
  ALGORITHM = "HS256"
  ISSUER = "CHANGE-ME"
  DECODE_OPTIONS = {
    # JWT verification functions to run
    verify_expiration: true, # JWT::ExpiredSignature

    # will be turned on after OTP flow deploy, and all prior tokens have expired
    verify_aud: false, # verify the audience, JWT::InvalidAudError
    verify_iat: false, # verify issued at date is not in the future, JWT::InvalidIatError
    verify_iss: false, # verify the issuer key is in the list of valid issuers, JWT::InvalidIssuerError
    verify_not_before: false, # JWT::ImmatureSignature
    verify_sub: false, # subject, JWT::InvalidSubError

    # 'verify_required_claims' is always called. the JWT lib checks whether this key exists in the options
    # required_claims: %w[aud exp iat iss nbf], # JWT::MissingRequiredClaim if specified fields DNE in decoded payload

    # will not be turned on after OTP flow deploy
    verify_jti: false, # json token id, true requires storing valid JWTs for checks, JWT::InvalidJtiError

    # other options
    algorithm: ALGORITHM,
    iss: [ISSUER],
    leeway: 30 # seconds of allowed clock skew
  }.freeze

  class << self
    def encode(payload:)
      payload.reverse_merge!(
        exp: 7.days.from_now.to_i,
        iss: ISSUER
      )

      JWT.encode(payload, JWT_SECRET, ALGORITHM)
    end

    def decode(token:, verify: true)
      JWT.decode(token, JWT_SECRET, verify, DECODE_OPTIONS)
    end
  end
end
