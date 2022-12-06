# frozen_string_literal: true

module Noticed
  # This is not a public API
  module WebHelpers
    SAFE_QPARAMS = %w[page direction]

    def root_path
      "#{env['SCRIPT_NAME']}/"
    end

    def current_path
      @current_path ||= request.path_info.gsub(/^\//,'')
    end

    # Merge options with current params, filter safe params, and stringify to query string
    def qparams(options)
      stringified_options = options.transform_keys(&:to_s)

      to_query_string(params.merge(stringified_options))
    end

    def to_query_string(params)
      params.map { |key, value|
        SAFE_QPARAMS.include?(key) ? "#{key}=#{CGI.escape(value.to_s)}" : next
      }.compact.join("&")
    end

    def list_params(params)
      params.reduce({}) do |hash, (key, value)|
        if value.is_a?(ActiveRecord::Base)
          hash[key] = "#{value.class.to_s}##{value.to_param}"
        else
          hash[key] = value.inspect
        end

        hash
      end
    end

    def strings(lang)
      @@strings ||= {}
      @@strings[lang] ||= begin
        # Allow sidekiq-web extensions to add locale paths
        # so extensions can be localized
        settings.locales.each_with_object({}) do |path, global|
          find_locale_files(lang).each do |file|
            strs = YAML.load(File.open(file))
            global.deep_merge!(strs[lang])
          end
        end
      end
    end

    def locale_files
      @@locale_files = settings.locales.flat_map do |path|
        Dir["#{path}/*.yml"]
      end
    end

    def find_locale_files(lang)
      locale_files.select { |file| file =~ /\/#{lang}\.yml$/ }
    end

    # Given a browser request Accept-Language header like
    # "fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4,ru;q=0.2", this function
    # will return "fr" since that's the first code with a matching
    # locale in web/locales
    def locale
      @locale ||= begin
        locale = 'en'.freeze
        languages = request.env['HTTP_ACCEPT_LANGUAGE'.freeze] || 'en'.freeze
        languages.downcase.split(','.freeze).each do |lang|
          next if lang == '*'.freeze
          lang = lang.split(';'.freeze)[0]
          break locale = lang if find_locale_files(lang).any?
        end
        locale
      end
    end

    def get_locale
      strings(locale)
    end

    def t(msg, options={})
      string = get_locale[msg] || msg
      if options.empty?
        string
      else
        string % options
      end
    end

    def environment_title_prefix
      environment = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"

      "[#{environment.upcase}] " unless environment == "production"
    end
  end
end
