class TutorialsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_username_configured

  rescue_from StandardError, with: :handle_tutorial_error

  def show
    @tutorial_steps = load_tutorial_steps
    @current_step = params[:step].present? ? params[:step].to_i : DEFAULT_TUTORIAL_STEP

    validate_tutorial_step(@current_step)
  rescue TutorialError => e
    Rails.logger.error "Tutorial error: #{e.message}"
    redirect_to diaries_path, alert: I18n.t("tutorials.error.step_not_found")
  end

  DEFAULT_TUTORIAL_STEP = 1
  MAX_TUTORIAL_STEPS = 4

  private

  class TutorialError < StandardError; end

  def ensure_username_configured
    return if current_user.username_configured?

    redirect_to setup_username_path, alert: I18n.t("tutorials.error.username_required")
  end

  def load_tutorial_steps
    {
      1 => { title: I18n.t("tutorials.steps.basic.title"), content: I18n.t("tutorials.steps.basic.content") },
      2 => { title: I18n.t("tutorials.steps.rating.title"), content: I18n.t("tutorials.steps.rating.content") },
      3 => { title: I18n.t("tutorials.steps.ai_til.title"), content: I18n.t("tutorials.steps.ai_til.content") },
      4 => { title: I18n.t("tutorials.steps.sharing.title"), content: I18n.t("tutorials.steps.sharing.content") }
    }
  rescue I18n::MissingTranslationData => e
    Rails.logger.error "Missing tutorial translation: #{e.message}"
    fallback_tutorial_steps
  end

  def validate_tutorial_step(step)
    return if step.between?(1, MAX_TUTORIAL_STEPS)

    raise TutorialError, "Invalid tutorial step: #{step}"
  end

  def fallback_tutorial_steps
    {
      1 => { title: "基本的な日記作成", content: "日記の作成方法を学びましょう" },
      2 => { title: "5段階評価システム", content: "気分や進捗を評価しましょう" },
      3 => { title: "AI TIL生成", content: "AIを使って学習記録を作成しましょう" },
      4 => { title: "GitHub連携とX投稿", content: "学習内容を共有しましょう" }
    }
  end

  def handle_tutorial_error(exception)
    Rails.logger.error "Tutorial controller error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?

    redirect_to diaries_path, alert: I18n.t("tutorials.error.general")
  end
end
