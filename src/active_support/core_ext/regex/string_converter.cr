require "json"

class Regex
  module StringConverter
    def self.from_json(value : JSON::PullParser) : Regex
      Regex.new(value.read_string)
    end
  end
end
