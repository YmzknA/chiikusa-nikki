require 'rails_helper'

RSpec.describe Diary, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:diary_answers) }
    it { should have_many(:til_candidates) }
  end
end
