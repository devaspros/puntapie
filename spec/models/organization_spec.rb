require "rails_helper"

describe Organization, type: :model do
  describe "associations" do
    describe "#invitations" do
      it "has many invitations" do
        organization = create(:organization)
        invitation = create(:invitation, organization: organization)
        invitations = organization.invitations

        expect(invitations).to include(invitation)
        expect(invitations.count).to eq(1)
      end
    end

    describe "#memberships" do
      it "has many memberships" do
        organization = create(:organization)
        user = create(:user)
        invitation = create(:invitation, organization: organization)
        membership = create(
          :membership,
          organization: organization,
          user: user,
          invitation: invitation,
          role: Role.find_by(name: "admin")
        )
        memberships = organization.memberships

        expect(memberships).to include(membership)
        expect(memberships.count).to eq(1)
      end
    end

    describe "#users" do
      it "has many users through memberships" do
        organization = create(:organization)
        user = create(:user)
        invitation = create(:invitation, organization: organization)
        create(
          :membership,
          organization: organization,
          user: user,
          invitation: invitation,
          role: Role.find_by(name: "admin")
        )
        users = organization.users

        expect(users).to include(user)
        expect(users.count).to eq(1)
      end
    end
  end
end
