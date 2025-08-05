class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :from_membership, class_name: "Membership", optional: true

  has_one :membership, dependent: :nullify

  validates :email, presence: true
  validates :email, uniqueness: { scope: :organization }
end

# == Schema Information
#
# Table name: invitations
#
#  id                 :integer          not null, primary key
#  email              :string
#  uuid               :string
#  from_membership_id :integer
#  organization_id    :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_invitations_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
