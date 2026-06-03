require "rails_helper"

describe Invitation, type: :model do
  describe "associations" do
    describe "#organization" do
      it "belongs to organization" do
        organization = create(:organization)
        invitation = create(:invitation, organization: organization)

        expect(invitation.organization).to eq(organization)
      end
    end

    describe "#from_membership" do
      it "belongs to from_membership" do
        organization = create(:organization)
        user = create(:user)
        invitation = create(:invitation, organization: organization)
        membership = create(
          :membership,
          user: user,
          organization: organization,
          invitation: invitation,
          role: Role.find_by(name: "admin")
        )

        invitation.update(from_membership: membership)

        expect(invitation.from_membership).to eq(membership)
      end
    end

    describe "#membership" do
      it "has one membership" do
        organization = create(:organization)
        user = create(:user)
        invitation = create(:invitation, organization: organization)
        membership = create(
          :membership,
          user: user,
          organization: organization,
          invitation: invitation,
          role: Role.find_by(name: "admin")
        )

        expect(invitation.membership).to eq(membership)
      end
    end
  end

  describe "validaciones de email" do
    it "requiere que el email esté presente" do
      invitation = build(:invitation, email: nil)

      invitation.valid?

      expect(invitation.errors[:email]).to include("no puede estar en blanco")
    end

    it "no permite emails duplicados en la misma organización" do
      existing_invitation = create(:invitation, email: "usuario@example.com")
      new_invitation = build(
        :invitation,
        email: "usuario@example.com",
        organization: existing_invitation.organization
      )

      new_invitation.valid?

      expect(new_invitation.errors[:email]).to include("ya ha sido tomado")
    end

    it "permite el mismo email en diferentes organizaciones" do
      create(:invitation, email: "usuario@example.com")
      new_org = create(:organization)
      new_invitation = build(
        :invitation,
        email: "usuario@example.com",
        organization: new_org
      )

      valid = new_invitation.valid?

      expect(valid).to be true
    end
  end
end
