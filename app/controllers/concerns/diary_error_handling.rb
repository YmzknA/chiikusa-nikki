# frozen_string_literal: true

module DiaryErrorHandling
  extend ActiveSupport::Concern

  private

  def handle_creation_error
    handle_error_data(diary_service.handle_creation_error(Question.all, params, current_user), :new)
  end

  def handle_update_error
    handle_error_data(diary_service.handle_update_error(Question.all), :edit)
  end

  def handle_error_data(error_data, view)
    @questions, @selected_answers = error_data.values_at(:questions, :selected_answers)
    @date = error_data[:date] if view == :new
    @existing_diary_for_error = error_data[:existing_diary_for_error] if view == :new
    flash.now[:alert] = error_data[:flash_message] if error_data[:flash_message]
    render view
  end
end
