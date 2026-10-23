require "rails_helper"

RSpec.describe "config/database.yml" do
  it "usa timeout y no retries para el lock de SQLite" do
    config = ActiveRecord::Base.connection_db_config.configuration_hash

    expect(config[:timeout]).to eq(5000)
    expect(config).not_to have_key(:retries)
    expect(config).not_to have_key(:host)
    expect(config).not_to have_key(:encoding)
  end
end
