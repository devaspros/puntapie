class User < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships

  belongs_to :current_organization, class_name: "Organization", optional: true

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         :registerable,
         :confirmable

  # Corre dentro de la transacción que crea al usuario: si falla la organización o la membresía,
  # el usuario tampoco se guarda y nunca queda una cuenta sin organización.
  after_create :create_and_attach_default_organization

  def current_membership
    return nil unless current_organization

    memberships.find_by(organization: current_organization)
  end

  def current_role
    current_membership&.role
  end

  def admin_of?(organization)
    memberships.joins(:role)
               .where(organization: organization, roles: { name: Role::ADMIN })
               .exists?
  end

  def owner_of?(organization)
    organization.owner?(self)
  end

  def member_of?(organization)
    memberships.where(organization: organization).exists?
  end

  def can_manage_organization?(organization)
    admin_of?(organization)
  end

  private

  def create_and_attach_default_organization
    org = Organization.create!(
      name: "#{first_name} Org",
      slug: "#{first_name.parameterize}-#{id}",
      owner: self
    )

    memberships.create!(organization: org, role: Role.find_by!(name: Role::ADMIN))
    update_column(:current_organization_id, org.id)
  end
end

# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  email                   :string           default(""), not null
#  encrypted_password      :string           default(""), not null
#  reset_password_token    :string
#  reset_password_sent_at  :datetime
#  remember_created_at     :datetime
#  first_name              :string
#  last_name               :string
#  admin                   :boolean          default(FALSE)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  current_organization_id :integer
#  confirmation_token      :string
#  confirmed_at            :datetime
#  confirmation_sent_at    :datetime
#  unconfirmed_email       :string
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
