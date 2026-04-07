require "rails_helper"

describe User, type: :model do
  describe "associations" do
    describe "#memberships" do
      it "has many memberships" do
        user = create(:user)
        organization = create(:organization)
        invitation = create(:invitation, organization: organization)
        membership = create(
          :membership,
          user: user,
          organization: organization,
          invitation: invitation,
          role: Role.find_by(name: "admin")
        )
        memberships = user.memberships

        expect(memberships).to include(membership)
      end
    end

    describe "#organizations" do
      it "has many organizations through memberships" do
        user = create(:user)
        organization = create(:organization)
        invitation = create(:invitation, organization: organization)
        create(
          :membership,
          user: user,
          organization: organization,
          invitation: invitation,
          role: Role.find_by(name: "admin")
        )
        organizations = user.organizations

        expect(organizations).to include(organization)
      end
    end

    describe "#current_organization" do
      it "belongs to current_organization" do
        user = create(:user)

        expect(user.current_organization).to be_a(Organization)
      end
    end
  end

  describe "validations" do
    describe "first_name" do
      it "is valid with a first_name" do
        user = build(:user, first_name: "John")

        expect(user).to be_valid
      end

      it "is invalid without a first_name" do
        user = build(:user, first_name: nil)

        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("no puede estar en blanco")
      end
    end

    describe "last_name" do
      it "is valid with a last_name" do
        user = build(:user, last_name: "Doe")

        expect(user).to be_valid
      end

      it "is invalid without a last_name" do
        user = build(:user, last_name: nil)

        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include("no puede estar en blanco")
      end
    end

    describe "email" do
      it "is valid with a valid email" do
        user = build(:user, email: "john.doe@example.com")

        expect(user).to be_valid
      end

      it "is invalid without an email" do
        user = build(:user, email: nil)

        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("no puede estar en blanco")
      end

      it "is invalid with a duplicate email" do
        create(:user, email: "john.doe@example.com")

        user = build(:user, email: "john.doe@example.com")

        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("ya ha sido tomado")
      end

      it "is invalid with an invalid email format" do
        user = build(:user, email: "invalid-email")

        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("es inválido")
      end
    end
  end
end
