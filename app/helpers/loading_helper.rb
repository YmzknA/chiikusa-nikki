module LoadingHelper
  def loading_link_to(name = nil, options = nil, html_options = nil, &)
    if block_given?
      html_options = options || {}
      options = name
      name = capture(&)
    else
      html_options ||= {}
    end

    # onclickでグローバル関数を呼び出す
    original_onclick = html_options[:onclick]
    loading_js = "if(window.loadingController) window.loadingController.showDelayed();"
    html_options[:onclick] = [loading_js, original_onclick].compact.join(" ").strip

    link_to(name, options, html_options)
  end

  def loading_button_to(name = nil, options = nil, html_options = nil, &)
    if block_given?
      html_options = options || {}
      options = name
      name = capture(&)
    else
      html_options ||= {}
    end

    # onclickでグローバル関数を呼び出す
    original_onclick = html_options[:onclick]
    loading_js = "if(window.loadingController) window.loadingController.showDelayed();"
    html_options[:onclick] = [loading_js, original_onclick].compact.join(" ").strip

    button_to(name, options, html_options)
  end

  def loading_form_with(**options, &)
    # onsubmitでグローバル関数を呼び出す
    original_onsubmit = options[:onsubmit]
    loading_js = [
      "setTimeout(function() {",
      "  if(window.loadingController) {",
      "    window.loadingController.showDelayed();",
      "  }",
      "}, 10);"
    ].join(" ")
    options[:onsubmit] = [loading_js, original_onsubmit].compact.join(" ").strip

    form_with(**options, &)
  end
end
