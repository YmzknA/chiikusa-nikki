require 'rails_helper'

RSpec.describe Question, type: :model do
  describe "associations" do
    it { should have_many(:answers) }
  end
end
