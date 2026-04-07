FactoryBot.define do
  factory :membership do
    association :user
    association :organization
    association :invitation
  end
end
