require "rails_helper"

describe User, type: :model do
  describe "associations" do
    describe "#memberships" do
      it "has many memberships" do
        user = create(:user)

        expect(user.memberships.count).to eq(1)
      end
    end

    describe "#organizations" do
      it "has many organizations through memberships" do
        user = create(:user)

        expect(user.organizations.count).to eq(1)
      end
    end

    describe "#current_organization" do
      it "belongs to current_organization" do
        user = create(:user)

        expect(user.current_organization).to be_a(Organization)
      end
    end
  end

  describe "default organization on create" do
    it "creates the organization owned by the user with an admin membership and sets it as current" do
      user = create(:user, first_name: "Ana")

      organization = user.current_organization
      expect(organization).to be_persisted
      expect(organization.name).to eq("Ana Org")
      expect(organization.slug).to eq("ana-#{user.id}")
      expect(organization.owner).to eq(user)
      expect(user.admin_of?(organization)).to be(true)
      expect(user.reload.current_organization).to eq(organization)
    end

    context "when the organization cannot be created" do
      before do
        allow(Organization).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not save the user" do
        expect { create(:user) }.to raise_error(ActiveRecord::RecordInvalid)

        expect(User.count).to eq(0)
      end
    end

    context "when the admin role is missing" do
      before do
        allow(Role).to receive(:find_by!).with(name: Role::ADMIN).and_raise(ActiveRecord::RecordNotFound)
      end

      it "does not save the user or the organization" do
        expect { create(:user) }.to raise_error(ActiveRecord::RecordNotFound)

        expect(User.count).to eq(0)
        expect(Organization.count).to eq(0)
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
