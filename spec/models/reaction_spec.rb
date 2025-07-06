require 'rails_helper'

RSpec.describe Reaction, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:diary) }
  end

  describe 'validations' do
    it { should validate_presence_of(:emoji) }
    it { should validate_inclusion_of(:emoji).in_array(Reaction::ALL_EMOJIS) }
    
    describe 'uniqueness validation' do
      let(:user) { create(:user) }
      let(:diary) { create(:diary, user: user) }
      
      before { create(:reaction, user: user, diary: diary, emoji: '😂') }
      
      it 'should not allow duplicate reactions for same user, diary, and emoji' do
        duplicate_reaction = build(:reaction, user: user, diary: diary, emoji: '😂')
        expect(duplicate_reaction).not_to be_valid
        expect(duplicate_reaction.errors[:user_id]).to include('は既に同じ絵文字でリアクションしています')
      end
      
      it 'should allow same emoji for different users' do
        other_user = create(:user)
        reaction = build(:reaction, user: other_user, diary: diary, emoji: '😂')
        expect(reaction).to be_valid
      end
      
      it 'should allow different emojis for same user' do
        reaction = build(:reaction, user: user, diary: diary, emoji: '😎')
        expect(reaction).to be_valid
      end
    end
  end

  describe 'constants' do
    it 'has defined emoji categories' do
      expect(Reaction::EMOJI_CATEGORIES).to be_a(Hash)
      expect(Reaction::EMOJI_CATEGORIES.keys).to contain_exactly(:emotion, :support, :learning, :reaction)
    end

    it 'has all emojis flattened from categories' do
      expected_emojis = Reaction::EMOJI_CATEGORIES.values.flat_map { |category| category[:emojis] }
      expect(Reaction::ALL_EMOJIS).to eq(expected_emojis)
    end
  end

  describe '.emoji_category' do
    it 'returns correct category for valid emoji' do
      expect(Reaction.emoji_category('😂')).to eq(:emotion)
      expect(Reaction.emoji_category('🔥')).to eq(:support)
      expect(Reaction.emoji_category('📚')).to eq(:learning)
      expect(Reaction.emoji_category('😲')).to eq(:reaction)
    end

    it 'returns nil for invalid emoji' do
      expect(Reaction.emoji_category('invalid')).to be_nil
    end
  end

  describe '#category' do
    let(:reaction) { create(:reaction, emoji: '😂') }

    it 'returns the category of the emoji' do
      expect(reaction.category).to eq(:emotion)
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:diary) { create(:diary, user: user) }
    let!(:reaction1) { create(:reaction, user: user, diary: diary, emoji: '😂') }
    let!(:reaction2) { create(:reaction, user: user, diary: diary, emoji: '🔥') }

    describe '.by_emoji' do
      it 'filters reactions by emoji' do
        expect(Reaction.by_emoji('😂')).to include(reaction1)
        expect(Reaction.by_emoji('😂')).not_to include(reaction2)
      end
    end

    describe '.by_diary' do
      it 'filters reactions by diary' do
        expect(Reaction.by_diary(diary)).to include(reaction1, reaction2)
      end
    end

    describe '.by_user' do
      it 'filters reactions by user' do
        expect(Reaction.by_user(user)).to include(reaction1, reaction2)
      end
    end
  end
end
