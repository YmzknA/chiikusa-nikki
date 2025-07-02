# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question, type: :model do
  describe "キャッシュ機能" do
    let!(:questions) { create_list(:question, 3) }

    before do
      Rails.cache.clear
      # 既存のQuestionデータをクリア
      Question.destroy_all
      # テスト用のQuestionを再作成
      @test_questions = create_list(:question, 3)
    end

    after do
      Question.destroy_all
    end

    describe ".cached_all" do
      it "キャッシュが空の場合はデータベースから取得し、キャッシュに保存する" do
        expect(Rails.cache).to receive(:fetch).with("questions_all", expires_in: 1.hour).and_call_original
        expect(Question).to receive(:all).and_call_original

        result = Question.cached_all
        expect(result.size).to eq(3)
      end

      it "キャッシュがある場合はキャッシュから取得する" do
        # 最初の呼び出しでキャッシュを作成
        Question.cached_all

        # 2回目の呼び出しではDBアクセスしない
        expect(Question).not_to receive(:all)
        result = Question.cached_all
        expect(result.size).to eq(3)
      end
    end

    describe ".cached_by_identifier" do
      it "identifierでインデックス化されたハッシュを返す" do
        result = Question.cached_by_identifier
        expect(result).to be_a(Hash)
        expect(result.keys).to match_array(@test_questions.map(&:identifier))
      end

      it "キャッシュが有効に動作する" do
        # 最初の呼び出し
        Question.cached_by_identifier

        # 2回目の呼び出しではDBアクセスしない
        expect(Question).not_to receive(:all)
        Question.cached_by_identifier
      end
    end

    describe ".cached_identifiers" do
      it "identifierのシンボル配列を返す" do
        result = Question.cached_identifiers
        expect(result).to be_a(Array)
        expect(result.all? { |id| id.is_a?(Symbol) }).to be true
        expect(result).to match_array(@test_questions.map { |q| q.identifier.to_sym })
      end
    end

    describe "キャッシュ無効化" do
      it "questionが更新されるとキャッシュがクリアされる" do
        # キャッシュを作成
        Question.cached_all
        Question.cached_by_identifier
        Question.cached_identifiers

        # キャッシュが存在することを確認
        expect(Rails.cache.exist?("questions_all")).to be true
        expect(Rails.cache.exist?("questions_by_identifier")).to be true
        expect(Rails.cache.exist?("question_identifiers")).to be true

        # questionを更新
        @test_questions.first.update!(label: "Updated Label")

        # キャッシュがクリアされることを確認
        expect(Rails.cache.exist?("questions_all")).to be false
        expect(Rails.cache.exist?("questions_by_identifier")).to be false
        expect(Rails.cache.exist?("question_identifiers")).to be false
      end

      it "questionが作成されるとキャッシュがクリアされる" do
        # キャッシュを作成
        Question.cached_all

        expect(Rails.cache.exist?("questions_all")).to be true

        # 新しいquestionを作成
        create(:question, identifier: "new_question", label: "New Question")

        # キャッシュがクリアされることを確認
        expect(Rails.cache.exist?("questions_all")).to be false
      end

      it "questionが削除されるとキャッシュがクリアされる" do
        # キャッシュを作成
        Question.cached_all

        expect(Rails.cache.exist?("questions_all")).to be true

        # questionを削除
        @test_questions.first.destroy!

        # キャッシュがクリアされることを確認
        expect(Rails.cache.exist?("questions_all")).to be false
      end
    end
  end
end
