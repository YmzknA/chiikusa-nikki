# frozen_string_literal: true

# Pagy initializer file for ちいくさ日記
# Customized for diary list pagination

# Pagy Variables
# Basic configuration for diary list pagination
Pagy::DEFAULT[:limit] = 20                    # 20 diaries per page
Pagy::DEFAULT[:size] = 3                      # pagination nav size
Pagy::DEFAULT[:ends] = true                   # show first/last page links

# Feature Extras

# Trim extra: Remove the page=1 param from links for cleaner URLs
require 'pagy/extras/trim'

# Overflow extra: Handle overflowing pages gracefully
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page         # redirect to last page if over limit

# I18n support for Japanese locale
Pagy::I18n.load(locale: 'ja')

# Freeze the configuration
Pagy::DEFAULT.freeze
