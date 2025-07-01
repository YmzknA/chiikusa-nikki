# frozen_string_literal: true

module SeedManagement
  extend ActiveSupport::Concern

  def increment_seed
    seed_service = SeedService.new(current_user).increment_daily_seed

    respond_to do |format|
      format.turbo_stream do
        render_seed_turbo_stream(seed_service)
      end
      format.html { redirect_to diaries_path, notice: seed_service.html_message_for_increment }
    end
  end

  def share_on_x
    @diary = current_user.diaries.find(params[:diary_id]) if params[:diary_id]
    seed_service = SeedService.new(current_user).increment_share_seed

    respond_to do |format|
      format.turbo_stream do
        render_seed_turbo_stream(seed_service)
      end
      format.html { redirect_to diary_path(@diary), flash_type_for_seed(seed_service) => seed_service.message }
      format.json { render json: json_response_for_seed(seed_service) }
    end
  end

  private

  def render_seed_turbo_stream(seed_service)
    if seed_service.success
      render turbo_stream: [
        turbo_stream.update("flash-messages", partial: "shared/flash", locals: {
                              flash: { notice: seed_service.message }
                            }),
        turbo_stream.update("seed-count", current_user.seed_count),
        turbo_stream.update("watering-button", partial: "shared/watering")
      ]
    else
      render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash", locals: {
                                                 flash: { alert: seed_service.message }
                                               })
    end
  end

  def flash_type_for_seed(seed_service)
    seed_service.success ? :notice : :alert
  end

  def json_response_for_seed(seed_service)
    if seed_service.success
      { success: true, seed_count: current_user.seed_count }
    else
      { success: false, message: seed_service.message }
    end
  end
end
