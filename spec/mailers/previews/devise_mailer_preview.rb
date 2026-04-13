class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    user = User.new(email: "usuario@ejemplo.com")
    AppMailer.confirmation_instructions(user, "fake_token_para_preview")
  end

  def reset_password_instructions
    user = User.new(email: "usuario@ejemplo.com")
    AppMailer.reset_password_instructions(user, "fake_token_para_preview")
  end
end
