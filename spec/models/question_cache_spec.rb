# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question, type: :model do
  describe "キャッシュ機能" do
    let!(:test_questions) { create_list(:question, 3) }

    before do
      Rails.cache.clear
      # 既存のQuestionデータをクリア
      Question.where.not(id: test_questions.map(&:id)).destroy_all
    end

    after do
      Rails.cache.clear
      Question.destroy_all
    end

    describe ".cached_all" do
      it "キャッシュが空の場合はデータベースから取得し、キャッシュに保存する" do
        # Clear cache to ensure we're testing fresh cache behavior
        Rails.cache.clear
        
        expect(Rails.cache).to receive(:fetch).with("questions_all", expires_in: Question::CACHE_EXPIRY).and_call_original

        result = Question.cached_all
        expect(result.size).to eq(3)
      end

      it "キャッシュがある場合はキャッシュから取得する" do
        # 最初の呼び出しでキャッシュを作成
        first_result = Question.cached_all
        expect(first_result.size).to eq(3)

        # キャッシュが存在することを確認
        expect(Rails.cache.read("questions_all")).not_to be_nil
        
        # 2回目の呼び出しで同じオブジェクトが返されることを確認
        second_result = Question.cached_all
        expect(second_result.size).to eq(3)
        expect(second_result.map(&:id)).to eq(first_result.map(&:id))
      end
    end

    describe ".cached_by_identifier" do
      it "identifierでインデックス化されたハッシュを返す" do
        result = Question.cached_by_identifier
        expect(result).to be_a(Hash)
        expect(result.keys).to match_array(test_questions.map(&:identifier))
      end

      it "キャッシュが有効に動作する" do
        # 最初の呼び出し
        first_result = Question.cached_by_identifier
        expect(first_result).to be_a(Hash)

        # キャッシュが存在することを確認
        expect(Rails.cache.read("questions_by_identifier")).not_to be_nil
        
        # 2回目の呼び出しで同じオブジェクトが返されることを確認
        second_result = Question.cached_by_identifier
        expect(second_result.keys).to eq(first_result.keys)
      end
    end

    describe ".cached_identifiers" do
      it "identifierのシンボル配列を返す" do
        result = Question.cached_identifiers
        expect(result).to be_a(Array)
        expect(result.all? { |id| id.is_a?(Symbol) }).to be true
        expect(result).to match_array(test_questions.map { |q| q.identifier.to_sym })
      end
    end

    describe "キャッシュ無効化" do
      it "questionが更新されるとキャッシュがクリアされる" do
        # キャッシュを作成
        Question.cached_all
        Question.cached_by_identifier  
        Question.cached_identifiers
        
        # キャッシュが存在することを確認
        expect(Rails.cache.read("questions_all")).not_to be_nil
        expect(Rails.cache.read("questions_by_identifier")).not_to be_nil
        expect(Rails.cache.read("questions_identifiers")).not_to be_nil

        # questionを更新
        test_questions.first.update!(label: "Updated Label")

        # キャッシュがクリアされることを確認
        expect(Rails.cache.read("questions_all")).to be_nil
        expect(Rails.cache.read("questions_by_identifier")).to be_nil
        expect(Rails.cache.read("questions_identifiers")).to be_nil
      end

      it "questionが作成されるとキャッシュがクリアされる" do
        # キャッシュを作成
        Question.cached_all

        expect(Rails.cache.read("questions_all")).not_to be_nil

        # 新しいquestionを作成
        create(:question, identifier: "new_question", label: "New Question")

        # キャッシュがクリアされることを確認
        expect(Rails.cache.read("questions_all")).to be_nil
      end

      it "questionが削除されるとキャッシュがクリアされる" do
        # キャッシュを作成
        Question.cached_all

        expect(Rails.cache.read("questions_all")).not_to be_nil

        # questionを削除
        test_questions.first.destroy!

        # キャッシュがクリアされることを確認
        expect(Rails.cache.read("questions_all")).to be_nil
      end
    end
  end
end
