require "rails_helper"

RSpec.describe DiaryAnswer, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:diary) }
    it { is_expected.to belong_to(:question) }
    it { is_expected.to belong_to(:answer) }
  end
end
