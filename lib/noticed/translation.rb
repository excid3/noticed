module Noticed
  module Translation
    extend ActiveSupport::Concern

    # Returns the +i18n_scope+ for the class. Overwrite if you want custom lookup.
    def i18n_scope
      :notifications
    end

    def class_scope
      self.class.name.underscore.tr("/", ".")
    end

    def translate(key, **options)
      I18n.translate(scope_translation_key(key), **options)
    end
    alias_method :t, :translate

    def scope_translation_key(key)
      if key.to_s.start_with?(".")
        "#{i18n_scope}.#{class_scope}#{key}"
      else
        key
      end
    end
  end
end
