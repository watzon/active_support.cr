# require "./duration"
require "./values/time_zone"
require "./core_ext/object/acts_like"
# require "./core_ext/date_and_time/compatibility"

struct TimeWithZone
  PRECISIONS = Hash(Int32, String).new { |h, n| h[n] = "%FT%T.%#{n}N" }
  PRECISIONS[0] = "%FT%T"

  def self.name
    "Time"
  end

  def iso8601(fraction_digits = 0)
    "#{to_s(PRECISIONS[fraction_digits.to_i])}#{formatted_offset(true, "Z")}"
  end
end
