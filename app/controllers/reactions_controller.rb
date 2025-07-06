class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diary

  def create
    @reaction = @diary.reactions.build(reaction_params)
    @reaction.user = current_user

    if @reaction.save
      render turbo_stream: [
        turbo_stream.replace("reactions_#{@diary.id}", partial: "shared/reactions",
                                                       locals: { diary: @diary, current_user: current_user }),
        turbo_stream.append("body", render_event_dispatcher("reaction:hide-modal", "reactions_#{@diary.id}"))
      ]
    else
      # Use flash message instead of JavaScript alert for security
      flash.now[:alert] = "リアクションの処理に失敗しました。もう一度お試しください。"
      render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
    end
  end

  def destroy
    @reaction = @diary.reactions.find_by(user: current_user, emoji: params[:id])
    if @reaction
      @reaction.destroy
      render turbo_stream: [
        turbo_stream.replace("reactions_#{@diary.id}", partial: "shared/reactions",
                                                       locals: { diary: @diary, current_user: current_user }),
        turbo_stream.append("body", render_event_dispatcher("reaction:hide-modal", "reactions_#{@diary.id}"))
      ]
    else
      head :not_found
    end
  end

  private

  def set_diary
    # 公開されている日記のみを対象とする（N+1対策でincludesを追加）
    @diary = Diary.includes(:reactions, reactions: :user)
                  .where(is_public: true)
                  .find(params[:diary_id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Unauthorized reaction access attempt: diary_id=#{params[:diary_id]}, " \
                      "user_id=#{current_user&.id}, ip=#{request.remote_ip}"
    head :not_found
  end

  def reaction_params
    params.require(:reaction).permit(:emoji)
  end

  # Secure event dispatcher helper method
  def render_event_dispatcher(event_name, target_id = nil, detail = {})
    helpers.content_tag(:div, "",
                        data: {
                          controller: "event-dispatcher",
                          event_dispatcher_event_name_value: event_name,
                          event_dispatcher_target_id_value: target_id,
                          event_dispatcher_detail_value: detail.to_json
                        },
                        style: "display: none;")
  end
end
