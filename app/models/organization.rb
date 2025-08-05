class Organization < ApplicationRecord
  has_many :invitations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  has_many :admin_memberships,
           -> { joins(:role).where(roles: { name: Role::ADMIN }) },
           class_name: "Membership"

  has_many :admin_users, through: :admin_memberships, source: :user

  # First admin user is considered the owner
  def owner
    admin_users.joins(:memberships)
              .where(memberships: { organization: self })
              .order("memberships.created_at ASC")
              .first
  end

  def owner?(user)
    owner == user
  end

  def has_admin?
    admin_memberships.exists?
  end

  def ensure_first_user_is_admin!
    return if has_admin?
    return unless memberships.exists?

    first_membership = memberships.order(:created_at).first
    admin_role = Role.find_by(name: Role::ADMIN)

    first_membership.update!(role: admin_role) if admin_role
  end
end

# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
