FactoryBot.define do
  factory :user do
    first_name { "Fuancho" }
    last_name { "Rois" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :confirmed do
      confirmed_at { DateTime.current }
    end
  end
end
