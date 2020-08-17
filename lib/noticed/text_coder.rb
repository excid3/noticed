module Noticed
  class TextCoder
    def self.load(data)
      return if data.nil?

      # Text columns need JSON parsing
      data = JSON.parse(data)
      ActiveJob::Arguments.send(:deserialize_argument, data)
    end

    def self.dump(data)
      return if data.nil?
      ActiveJob::Arguments.send(:serialize_argument, data).to_json
    end
  end
end
