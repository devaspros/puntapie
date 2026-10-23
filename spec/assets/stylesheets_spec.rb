require "rails_helper"

RSpec.describe "Hojas de estilo" do
  it "compila Bootstrap y los estilos propios en application.css" do
    css = Rails.application.assets.find_asset("application.css").to_s

    expect(css).to include(".btn")
    expect(css).to include(".sidebar")
    expect(css).to include(".content-container")
  end

  it "compila Bootstrap y los estilos propios en login.css" do
    css = Rails.application.assets.find_asset("login.css").to_s

    expect(css).to include(".btn")
    expect(css).to include(".form-signin")
  end

  # libsass redondea los colores a hex (#094179) y Dart Sass los deja con decimales
  # (rgb(3.66%, 25.63%, 47.32%)), así que se comparan los canales redondeados a 0-255.
  it "mantiene los colores de hover de la landing" do
    css = Rails.application.assets.find_asset("landing.css").to_s

    button_hover = css[/\.btn-primary-custom:hover\s*\{[^}]*\}/]
    footer_hover = css[/\.footer-link:hover\s*\{[^}]*\}/]

    expect(rgb_channels(button_hover)).to eq([9, 65, 121])
    expect(rgb_channels(footer_hover)).to eq([72, 77, 86])
  end

  def rgb_channels(rule)
    hex = rule[/#(\h{6})\b/, 1]
    return hex.scan(/../).map { |channel| channel.to_i(16) } if hex

    rule[/rgb\(([^)]*)\)/, 1].split(/[\s,]+/).map { |channel| (channel.to_f * 255 / 100).round }
  end
end
