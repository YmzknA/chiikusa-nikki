module ApplicationHelper
  # サイドバーとモバイルナビゲーションを非表示にするページかどうかを判定
  def hide_navigation?
    (controller_name == 'home' && action_name == 'index') ||
    (controller_name == 'users' && action_name == 'setup_username')
  end
end
