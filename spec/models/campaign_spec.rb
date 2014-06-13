require 'rails_helper'

RSpec.describe Campaign, type: :model do

  describe "concerning validations" do
    it "should have a valid factory" do
      expect(build(:campaign)).to be_valid
    end

    it "should require the name" do
      expect(build(:campaign, name: nil)).to_not be_valid
    end

    it "should require a unique name regardless of case" do
      expect(create(:campaign, name: 'campaign')).to be_valid
      expect(build(:campaign, name: 'campaign')).to_not be_valid
      expect(build(:campaign, name: 'CAMPAIGN')).to_not be_valid
    end

    it "should require the state" do
      expect {
        build(:campaign, state: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should require the district" do
      expect {
        build(:campaign, district: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should require the school" do
      expect {
        build(:campaign, school: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should require the campaignable" do
      expect(build(:campaign, campaignable: nil)).to_not be_valid
    end

    it "should require the school_wide" do
      expect(build(:campaign, school_wide: nil)).to_not be_valid
    end

    it "should require a unique slug" do
      expect(create(:campaign, slug: '12345')).to be_valid
      expect(build(:campaign, slug: '12345')).to_not be_valid
    end

    it "should validate that the district is associated with the proper state" do
      utah = create(:state, name: 'Utah', abbr: 'UT')
      nevada = create(:state, name: 'Nevada', abbr: 'NV')
      district_1 = create(:district, name: 'Washington County', state: utah)
      district_2 = create(:district, name: 'Mojave County', state: nevada)
      expect(build(:campaign, state: utah, district: district_2)).to_not be_valid
    end

    it "should validate that the school is associated with the proper district" do
      utah = create(:state, name: 'Utah', abbr: 'UT')
      nevada = create(:state, name: 'Nevada', abbr: 'NV')
      washington = create(:district, name: 'Washington County', state: utah)
      mojave = create(:district, name: 'Mojave County', state: nevada)
      snow_canyon = create(:school, name: 'Snow Canyon', district: washington)
      desert_hills = create(:school, name: 'Desert Hills', district: mojave)
      expect(utah.districts).to match_array([washington])
      expect(nevada.districts).to match_array([mojave])
      expect(washington.schools).to match_array([snow_canyon])
      expect(mojave.schools).to match_array([desert_hills])
      expect(snow_canyon.state).to eq(utah)
      expect(desert_hills.state).to eq(nevada)
      expect(build(:campaign, district: washington, school: desert_hills, state: utah)).to_not be_valid
    end

    it "should NOT validate that the teacher is associated with the proper school if it is school wide" do
      utah = create(:state, name: 'Utah', abbr: 'UT')
      nevada = create(:state, name: 'Nevada', abbr: 'NV')
      washington = create(:district, name: 'Washington County', state: utah)
      mojave = create(:district, name: 'Mojave County', state: nevada)
      snow_canyon = create(:school, name: 'Snow Canyon', district: washington)
      desert_hills = create(:school, name: 'Desert Hills', district: mojave)
      teacher_1 = create(:teacher, first_name: 'Mark', last_name: 'Holmberg', school: snow_canyon)
      teacher_2 = create(:teacher, first_name: 'Scott', last_name: 'Holmberg', school: desert_hills)
      expect(utah.districts).to match_array([washington])
      expect(nevada.districts).to match_array([mojave])
      expect(washington.schools).to match_array([snow_canyon])
      expect(mojave.schools).to match_array([desert_hills])
      expect(snow_canyon.state).to eq(utah)
      expect(desert_hills.state).to eq(nevada)
      expect(snow_canyon.teachers).to match_array([teacher_1])
      expect(desert_hills.teachers).to match_array([teacher_2])
      expect(build(:campaign, district: washington, school: snow_canyon, state: utah, campaignable: teacher_2, school_wide: true)).to be_valid
    end

    it "should validate that the teacher is associated with the proper school if it is NOT school wide" do
      utah = create(:state, name: 'Utah', abbr: 'UT')
      nevada = create(:state, name: 'Nevada', abbr: 'NV')
      washington = create(:district, name: 'Washington County', state: utah)
      mojave = create(:district, name: 'Mojave County', state: nevada)
      snow_canyon = create(:school, name: 'Snow Canyon', district: washington)
      desert_hills = create(:school, name: 'Desert Hills', district: mojave)
      teacher_1 = create(:teacher, first_name: 'Mark', last_name: 'Holmberg', school: snow_canyon)
      teacher_2 = create(:teacher, first_name: 'Scott', last_name: 'Holmberg', school: desert_hills)
      expect(utah.districts).to match_array([washington])
      expect(nevada.districts).to match_array([mojave])
      expect(washington.schools).to match_array([snow_canyon])
      expect(mojave.schools).to match_array([desert_hills])
      expect(snow_canyon.state).to eq(utah)
      expect(desert_hills.state).to eq(nevada)
      expect(snow_canyon.teachers).to match_array([teacher_1])
      expect(desert_hills.teachers).to match_array([teacher_2])
      expect(build(:campaign, district: washington, school: snow_canyon, state: utah, campaignable: teacher_2, school_wide: false)).to_not be_valid
    end
  end

  describe "concerning relations" do
    it "should belong to a state" do
      state = create(:state, name: 'Utah', abbr: 'UT')
      campaign = create(:campaign, state: state)
      expect(campaign.state).to eql(state)
    end

    it "should belong to a district" do
      district = create(:district, name: 'Washington County')
      campaign = create(:campaign, district: district, state: district.state)
      expect(campaign.district).to eql(district)
    end

    it "should belong to a school" do
      school = create(:school, name: 'Snow Canyon')
      campaign = create(:campaign, school: school, district: school.district, state: school.state)
      expect(campaign.school).to eql(school)
    end

    it "should belong to a campaignable for a teacher" do
      teacher = create(:teacher, first_name: 'Mark', last_name: 'Holmberg')
      campaign = create(:campaign, campaignable: teacher, school: teacher.school, district: teacher.school.district, state: teacher.school.district.state, school_wide: false)
      expect(campaign.campaignable).to eql(teacher)
    end

    it "should belong to a campaignable for a school" do
      snow_canyon = create(:school, name: 'Snow Canyon')
      campaign = create(:campaign, campaignable: snow_canyon, school: snow_canyon, district: snow_canyon.district, state: snow_canyon.district.state, school_wide: true)
      expect(campaign.campaignable).to eql(snow_canyon)
    end

    it "should have many contributions" do
      campaign = create(:campaign)
      contribution_1 = create(:contribution, campaign: campaign)
      contribution_2 = create(:contribution, campaign: campaign)
      expect(campaign.contributions).to match_array([contribution_1, contribution_2])
    end
  end

  describe "concerning ActiveRecord callbacks" do
    it "should generate a unique slug" do
      expect(create(:campaign).slug).to_not be_nil
    end

    it "should not be destroyable if it is active?" do
      campaign = create(:campaign, name: 'Campaign', active: true)
      expect {
        campaign.destroy
      }.to_not change(Campaign, :count)
    end

    it "should not be destroyable if it has contributions" do
      campaign = create(:campaign, name: 'Campaign', active: false)
      contribution = create(:contribution, campaign: campaign)
      expect {
        campaign.destroy
      }.to_not change(Campaign, :count)
    end
  end

end