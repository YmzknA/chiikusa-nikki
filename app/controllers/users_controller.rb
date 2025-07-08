class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_username_set, only: [:setup_username, :update_username]

  def setup_username
    # ユーザー名が未設定の場合のみアクセス可能
  end

  def update_username
    if current_user.update(username_params)
      # アバター取得処理
      handle_avatar_fetch_for_provider("github") if params[:user][:fetch_github_avatar] == "true"
      handle_avatar_fetch_for_provider("google") if params[:user][:fetch_google_avatar] == "true"

      redirect_to tutorial_path, notice: "ユーザー名を設定しました！まずは使い方を確認しましょう 🌱"
    else
      render :setup_username, status: :unprocessable_entity
    end
  end

  def destroy
    return handle_unauthorized_deletion unless valid_deletion_request?
    return handle_invalid_confirmation unless valid_username_confirmation?

    user = current_user
    username = user.username

    Rails.logger.info "User deletion initiated: #{username} (ID: #{user.id})"

    ActiveRecord::Base.transaction do
      validate_related_data_integrity(user)

      if user.destroy
        sign_out # セッションをクリア
        reset_session # セッションを完全にリセット
        Rails.logger.info "User deletion completed: #{username}"
        redirect_to root_path, notice: "#{username}さんのアカウントを削除しました。ご利用ありがとうございました。"
      else
        Rails.logger.error "User deletion failed: #{user.errors.full_messages.join(', ')}"
        redirect_to profile_path, alert: "アカウントの削除に失敗しました。時間をおいて再度お試しください。"
      end
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey => e
    Rails.logger.error "User deletion failed due to data integrity: #{e.message}"
    redirect_to profile_path, alert: "関連データの削除に失敗しました。時間をおいて再度お試しください。"
  rescue StandardError => e
    Rails.logger.error "User deletion failed: #{e.message}"
    redirect_to profile_path, alert: "アカウントの削除に失敗しました。時間をおいて再度お試しください。"
  end

  private

  def username_params
    params.require(:user).permit(:username)
  end

  def handle_avatar_fetch_for_provider(provider)
    case provider
    when "github"
      return unless current_user.github_id.present?

      avatar_url = current_user.github_avatar_url
      log_message = "GitHub avatar fetched"
    when "google"
      return unless current_user.google_id.present?

      avatar_url = current_user.google_avatar_url
      log_message = "Google avatar fetched"
    else
      return
    end

    return unless avatar_url.present?

    begin
      validated_url = AvatarSecurityService.validate_url!(avatar_url)
      current_user.remote_avatar_url = validated_url
      current_user.save!
      AvatarUpdateLogger.log_success(current_user.id, provider)
    rescue SecurityError => e
      AvatarUpdateLogger.log_error(current_user.id, provider, e)
      return
    rescue StandardError => e
      AvatarUpdateLogger.log_error(current_user.id, provider, e)
    end
  end

  def redirect_if_username_set
    return unless current_user.username_configured?

    redirect_to diaries_path
  end

  def valid_deletion_request?
    current_user.present? && request.delete?
  end

  def valid_username_confirmation?
    params[:confirm_username].present? && params[:confirm_username] == current_user.username
  end

  def handle_unauthorized_deletion
    Rails.logger.warn "Unauthorized deletion attempt for user #{current_user&.id}"
    redirect_to profile_path, alert: "不正な削除リクエストです。"
  end

  def handle_invalid_confirmation
    Rails.logger.warn "Invalid username confirmation for user #{current_user.id}"
    redirect_to profile_path, alert: "ユーザー名の確認が正しくありません。"
  end

  def validate_related_data_integrity(user)
    return if user.diaries.empty?

    # 削除前の関連データの整合性チェック
    user.diaries.includes(:diary_answers, :til_candidates).each do |diary|
      next if diary.diary_answers.all?(&:valid?) && diary.til_candidates.all?(&:valid?)

      raise ActiveRecord::RecordInvalid, "Related data integrity check failed"
    end
  end
end
