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

  test "I18n support" do
    assert_equal I18n.t("hello"), I18nExample.new.message
    assert_equal "hello", I18nExample.new.send(:scope_translation_key, "hello")
  end

  test "I18n supports namespaces" do
    assert_equal "notifications.noticed/i18n_example.message", Noticed::I18nExample.new.send(:scope_translation_key, ".message")
  end
end
