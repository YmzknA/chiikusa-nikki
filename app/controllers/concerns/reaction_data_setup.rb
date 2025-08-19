module ReactionDataSetup
  extend ActiveSupport::Concern

  private

  def setup_reaction_data(diaries = nil)
    target_diaries = diaries || @diaries || [@diary].compact
    return if target_diaries.empty?

    diary_ids = target_diaries.respond_to?(:map) ? target_diaries.map(&:id) : [target_diaries.id]
    @reactions_summary_data = Reaction.emoji_summary_by_diary(diary_ids)
    @current_user_reactions_data = Reaction.user_reactions_by_diary(diary_ids, current_user)
  end
end
