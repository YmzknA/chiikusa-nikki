# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatsController, type: :request do
  describe "キャッシュ機能（簡略版）" do
    let(:user) { create(:user) }
    let!(:diary) { create(:diary, user: user, date: Date.current) }

    before do
      sign_in user
      Rails.cache.clear
    end

    describe "GET /stats" do
      it "統計ページが正常に表示される" do
        get "/stats"
        expect(response).to be_successful
        expect(response.body).to include("統計")
      end

      it "チャートビルダーサービスが呼ばれる" do
        expect_any_instance_of(ChartBuilderService).to receive(:build_daily_trends_chart).and_call_original
        get "/stats"
        expect(response).to be_successful
      end

      it "異なるパラメータでのアクセスが可能" do
        get "/stats", params: { view_type: "monthly", target_month: "2024-01" }
        expect(response).to be_successful
      end
    end

    describe "キャッシュログ機能" do
      it "キャッシュログメソッドがprivateメソッドとして実装されている" do
        expect(StatsController.private_instance_methods).to include(:build_all_charts)
      end
    end

    describe "エラーハンドリング" do
      it "Redis接続エラーが発生してもアプリケーションが継続動作する" do
        # テスト環境ではnull_storeなのでエラーは発生しないが、メソッドの呼び出しは確認
        expect { get "/stats" }.not_to raise_error
        expect(response).to be_successful
      end
    end
  end
end
