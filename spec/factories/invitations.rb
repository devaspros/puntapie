FactoryBot.define do
  factory :invitation do
    association :organization

    sequence(:email) { |n| "invited#{n}@example.com" }
    uuid { SecureRandom.hex }
  end
end
