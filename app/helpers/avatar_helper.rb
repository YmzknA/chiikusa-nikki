module AvatarHelper
  def avatar_image(user, size: 40, css_class: "rounded-full")
    if user.avatar_url.present?
      image_tag(user.avatar_url, alt: user.username, class: css_class,
                                 size: "#{size}x#{size}")
    else
      avatar_initial(user, size: size, css_class: css_class)
    end
  end

  def avatar_initial(user, size: 40, css_class: "rounded-full")
    content_tag(:div, user.initials,
                class: "#{css_class} bg-green-500 text-white flex items-center justify-center text-sm font-semibold",
                style: "width: #{size}px; height: #{size}px;")
  end

  def avatar_url(user)
    user.avatar_url || nil
  end
end
