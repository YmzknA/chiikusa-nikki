require "rails_helper"

RSpec.describe Diary, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:diary_answers) }
    it { is_expected.to have_many(:til_candidates) }
  end
end
