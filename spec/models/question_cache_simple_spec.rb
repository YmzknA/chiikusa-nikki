# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question, type: :model do
  describe "キャッシュ機能（簡略版）" do
    before do
      Rails.cache.clear
      Question.destroy_all
    end

    after do
      Question.destroy_all
    end

    describe ".cached_all" do
      it "全てのQuestionを返す" do
        questions = create_list(:question, 3)
        result = Question.cached_all
        expect(result.size).to eq(3)
        expect(result.map(&:id)).to match_array(questions.map(&:id))
      end
    end

    describe ".cached_by_identifier" do
      it "identifierでインデックス化されたハッシュを返す" do
        questions = create_list(:question, 2)
        result = Question.cached_by_identifier
        expect(result).to be_a(Hash)
        expect(result.keys).to match_array(questions.map(&:identifier))
      end
    end

    describe ".cached_identifiers" do
      it "identifierのシンボル配列を返す" do
        questions = create_list(:question, 2)
        result = Question.cached_identifiers
        expect(result).to be_a(Array)
        expect(result.all? { |id| id.is_a?(Symbol) }).to be true
        expect(result).to match_array(questions.map { |q| q.identifier.to_sym })
      end
    end

    describe "キャッシュ無効化メソッド" do
      it "clear_questions_cacheメソッドが定義されている" do
        question = create(:question)
        expect(question.private_methods).to include(:clear_questions_cache)
      end
    end
  end
end
