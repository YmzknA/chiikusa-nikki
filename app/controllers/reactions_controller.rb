class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diary

  def create
    @reaction = @diary.reactions.build(reaction_params)
    @reaction.user = current_user

    if @reaction.save
      render turbo_stream: turbo_stream.replace("reactions_#{@diary.id}", partial: 'shared/reactions', locals: { diary: @diary, current_user: current_user })
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @reaction = @diary.reactions.find_by(user: current_user, emoji: params[:id])
    if @reaction
      @reaction.destroy
      render turbo_stream: turbo_stream.replace("reactions_#{@diary.id}", partial: 'shared/reactions', locals: { diary: @diary, current_user: current_user })
    else
      head :not_found
    end
  end

  private

  def set_diary
    @diary = Diary.find(params[:diary_id])
  end

  def reaction_params
    params.require(:reaction).permit(:emoji)
  end
end
