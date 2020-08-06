module Noticed
  class Coder
    def self.load(data)
      return if data.nil?
      ActiveJob::Arguments.send(:deserialize_argument, JSON.parse(data))
    end

    def self.dump(data)
      return if data.nil?
      ActiveJob::Arguments.send(:serialize_argument, data).to_json
    end
  end
end
