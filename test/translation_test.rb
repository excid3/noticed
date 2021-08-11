require "test_helper"

class TranslationTest < ActiveSupport::TestCase
  class I18nExample < Noticed::Base
    def message
      t("hello")
    end
  end

  class Noticed::I18nExample < Noticed::Base
    def message
      t(".message")
    end
  end

  class ::ScopedI18nExample < Noticed::Base
    def i18n_scope
      :noticed
    end

    def message
      t(".message")
    end
  end

  test "I18n support" do
    assert_equal "hello", I18nExample.new.send(:scope_translation_key, "hello")
    assert_equal "Hello world", I18nExample.new.message
  end

  test "I18n supports namespaces" do
    assert_equal "notifications.noticed.i18n_example.message", Noticed::I18nExample.new.send(:scope_translation_key, ".message")
    assert_equal "This is a notification", Noticed::I18nExample.new.message
  end

  test "I18n supports custom scopes" do
    assert_equal "noticed.scoped_i18n_example.message", ScopedI18nExample.new.send(:scope_translation_key, ".message")
    assert_equal "This is a custom scoped translation", ScopedI18nExample.new.message
  end
end
