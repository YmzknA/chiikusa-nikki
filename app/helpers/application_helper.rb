module ApplicationHelper
  include Pagy::Frontend
  # サイドバーとモバイルナビゲーションを非表示にするページかどうかを判定
  def hide_navigation?
    (controller_name == "home" && action_name == "index") ||
      (controller_name == "users" && action_name == "setup_username")
  end

  def default_meta_tags
    {
      site: "ちいくさ日記",
      title: "ちいくさ日記",
      description: "毎日1分、簡単日記で草生やし",
      charset: "utf-8",
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: "website",
        url: request.original_url,
        image: image_url("ogp.png"),
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        image: image_url("ogp.png")
      }
    }
  end
end
