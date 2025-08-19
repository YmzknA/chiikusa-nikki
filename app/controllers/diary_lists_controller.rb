class DiaryListsController < ApplicationController
  include DiaryFiltering

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

  private

  def setup_reaction_data
    return if @diaries.empty?

    diary_ids = @diaries.map(&:id)
    @reactions_summary_data = Reaction.emoji_summary_by_diary(diary_ids)
    @current_user_reactions_data = Reaction.user_reactions_by_diary(diary_ids, current_user)
  end
end
