require "rails_helper"

describe Membership, type: :model do
  describe "asociaciones" do
    it "pertenece a una organización opcional" do
      membership = build(:membership, organization: nil, role: Role.find_by(name: "admin"))

      valid = membership.valid?

      expect(valid).to be true
      expect(membership.organization).to be_nil
    end

    it "puede pertenecer a una organización" do
      organization = create(:organization)
      membership = build(:membership, organization: organization)

      membership.save

      expect(membership.organization).to eq(organization)
    end

    it "pertenece a un usuario requerido" do
      membership = build(:membership, user: nil)

      membership.valid?

      expect(membership.errors[:user]).to include("debe existir")
    end

    it "puede tener una invitación asociada" do
      organization = create(:organization)
      invitation = create(:invitation, organization: organization)
      membership = build(:membership, invitation: invitation, role: Role.find_by(name: "admin"))

      membership.save

      expect(membership.invitation).to eq(invitation)
      expect(invitation.reload.membership).to eq(membership)
    end

    it "destruye la invitación asociada cuando se configura dependent: :destroy" do
      organization = create(:organization)
      invitation = create(:invitation, organization: organization)
      membership = create(:membership, invitation: invitation, role: Role.find_by(name: "admin"))

      membership.destroy

      expect { invitation.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
