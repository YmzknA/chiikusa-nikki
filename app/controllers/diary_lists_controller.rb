class DiaryListsController < ApplicationController
  include DiaryFiltering
  include ReactionDataSetup

  before_action :authenticate_user!

  def index
    @selected_month = params[:month].present? ? params[:month] : "all"

    # リスト表示用の詳細クエリ（ページネーション付き）
    base_query = filter_diaries_by_month(
      current_user.diaries.includes(
        :til_candidates,
        { diary_answers: :answer },
        { reactions: :user }
      ),
      @selected_month
    ).order(date: :desc, created_at: :desc)

    # Pagyでページネーション
    @pagy, @diaries = pagy(base_query, limit: 31)

    # リアクション集計データの設定（リスト表示のみ）
    setup_reaction_data

    @available_months = available_months
  end
end
