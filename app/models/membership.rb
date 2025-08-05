class Membership < ApplicationRecord
  scope :admins, -> { joins(:role).where(roles: { name: Role::ADMIN }) }
  scope :members, -> { joins(:role).where(roles: { name: Role::MEMBER }) }
  scope :viewers, -> { joins(:role).where(roles: { name: Role::VIEWER }) }

  belongs_to :organization, optional: true
  belongs_to :user
  belongs_to :invitation, optional: true, dependent: :destroy
  belongs_to :role

  validates :user_id, uniqueness: { scope: :organization_id }

  validate :role_belongs_to_valid_set

  def admin?
    role.name == Role::ADMIN
  end

  def member?
    role.name == Role::MEMBER
  end

  def viewer?
    role.name == Role::VIEWER
  end

  private

  def role_belongs_to_valid_set
    return unless role

    unless Role::VALID_ROLES.include?(role.name)
      errors.add(:role, "must be one of: #{Role::VALID_ROLES.join(', ')}")
    end
  end
end

# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  organization_id :integer          not null
#  user_id         :integer          not null
#  invitation_id   :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  role_id         :integer          not null
#
# Indexes
#
#  index_memberships_on_invitation_id    (invitation_id)
#  index_memberships_on_organization_id  (organization_id)
#  index_memberships_on_role_id          (role_id)
#  index_memberships_on_user_id          (user_id)
#
# Foreign Keys
#
#  invitation_id    (invitation_id => invitations.id)
#  organization_id  (organization_id => organizations.id)
#  role_id          (role_id => roles.id)
#  user_id          (user_id => users.id)
#
