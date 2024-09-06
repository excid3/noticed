require "test_helper"

class TranslationTest < ActiveSupport::TestCase
  class I18nExample < Noticed::Event
    deliver_by :test do |config|
      config.message = -> { t("hello") }
    end

    def message
      t("hello")
    end

    def html_message
      t("message_html")
    end
  end

  class Noticed::I18nExample < Noticed::Event
    def message
      t(".message")
    end
  end

  class ::ScopedI18nExample < Noticed::Event
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
    assert_equal "notifiers.noticed.i18n_example.message", Noticed::I18nExample.new.send(:scope_translation_key, ".message")
    assert_equal "This is a notification", Noticed::I18nExample.new.message
  end

  test "I18n supports custom scopes" do
    assert_equal "noticed.scoped_i18n_example.message", ScopedI18nExample.new.send(:scope_translation_key, ".message")
    assert_equal "This is a custom scoped translation", ScopedI18nExample.new.message
  end

  if defined?(ActiveSupport::HtmlSafeTranslation)
    test "I18n supports html safe translations" do
      message = I18nExample.new.html_message
      assert_equal "<p>Hello world</p>", message
      assert message.html_safe?
    end
  end

  test "delivery method blocks can use translations" do
    block = I18nExample.delivery_methods[:test].config[:message]
    assert_equal "Hello world", noticed_notifications(:one).instance_exec(&block)
  end

  test "ephemeral translations" do
    assert_equal "Hello world", EphemeralNotifier.new.t("hello")
  end

  test "ephemeral notification translations" do
    assert_equal "Hello world", EphemeralNotifier::Notification.new.t("hello")
  end
end
