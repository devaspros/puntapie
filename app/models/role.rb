class Role < ApplicationRecord
  ADMIN = "admin".freeze
  MEMBER = "member".freeze
  VIEWER = "viewer".freeze
  VALID_ROLES = [ADMIN, MEMBER, VIEWER].freeze

  scope :admin, -> { where(name: ADMIN) }
  scope :member, -> { where(name: MEMBER) }
  scope :viewer, -> { where(name: VIEWER) }

  has_many :memberships, dependent: :restrict_with_error
  has_many :users, through: :memberships
  has_many :organizations, through: :memberships

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :name, inclusion: { in: VALID_ROLES }
end

# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
