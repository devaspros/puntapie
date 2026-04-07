FactoryBot.define do
  factory :user do
    first_name { "Fuancho" }
    last_name { "Rois" }
    email { "user#{rand(1000)}@example.com" }
    password { "password123" }

    trait :confirmed do
      confirmed_at { DateTime.current }
    end
  end
end
