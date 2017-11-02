require "i18n"

require "./duration/iso8601_parser"
require "./duration/iso8601_serializer"
require "./core_ext/array/conversions"
require "./core_ext/object/acts_like"
require "./core_ext/string/filters"
require "./core_ext/hash/sort"

module ActiveSupport
  # Provides accurate date and time measurements using Date#advance and
  # Time#advance, respectively. It mainly supports the methods on Numeric.
  #
  #   1.month.ago       # equivalent to Time.now.advance(months: -1)
  class Duration
    struct Scalar < Number
      getter :value
      delegate :to_i, :to_f, :to_s, to: :value

      def initialize(@value : Int32 | Int64)
      end

      def_hash object_id

      def coerce(other)
        [Scalar.new(other), self]
      end

      def -
        Scalar.new(-value)
      end

      def <=>(other)
        if Scalar === other || Duration === other
          value <=> other.value
        elsif Numeric === other
          value <=> other
        else
          nil
        end
      end

      def +(other)
        if Duration === other
          seconds   = value + other.parts[:seconds]
          new_parts = other.parts.merge(seconds: seconds)
          new_value = value + other.value

          Duration.new(new_value, new_parts)
        else
          calculate(:+, other)
        end
      end

      def -(other)
        if Duration === other
          seconds   = value - other.parts[:seconds]
          new_parts = other.parts.map { |part, other_value| [part, -other_value] }.to_h
          new_parts = new_parts.merge(seconds: seconds)
          new_value = value - other.value

          Duration.new(new_value, new_parts)
        else
          calculate(:-, other)
        end
      end

      def *(other)
        if Duration === other
          new_parts = other.parts.map { |part, other_value| [part, value * other_value] }.to_h
          new_value = value * other.value

          Duration.new(new_value, new_parts)
        else
          calculate(:*, other)
        end
      end

      def /(other)
        if Duration === other
          value / other.value
        else
          calculate(:/, other)
        end
      end

      def %(other)
        if Duration === other
          Duration.build(value % other.value)
        else
          calculate(:%, other)
        end
      end

      private def calculate(op, other)
        if Scalar === other
          Scalar.new(value.public_send(op, other.value))
        elsif Numeric === other
          Scalar.new(value.public_send(op, other))
        else
          raise_type_error(other)
        end
      end

      private def raise_type_error(other)
        raise TypeError.new "no implicit conversion of #{other.class} into #{self.class}"
      end
    end

    SECONDS_PER_MINUTE = 60
    SECONDS_PER_HOUR   = 3600
    SECONDS_PER_DAY    = 86400
    SECONDS_PER_WEEK   = 604800
    SECONDS_PER_MONTH  = 2629746  # 1/12 of a gregorian year
    SECONDS_PER_YEAR   = 31556952 # length of a gregorian year (365.2425 days)

    PARTS_IN_SECONDS = {
      seconds: 1,
      minutes: SECONDS_PER_MINUTE,
      hours:   SECONDS_PER_HOUR,
      days:    SECONDS_PER_DAY,
      weeks:   SECONDS_PER_WEEK,
      months:  SECONDS_PER_MONTH,
      years:   SECONDS_PER_YEAR
    }

    PARTS = [:years, :months, :weeks, :days, :hours, :minutes, :seconds]

    getter :value, :parts

    # Creates a new Duration from string formatted according to ISO 8601 Duration.
    #
    # See {ISO 8601}[https://en.wikipedia.org/wiki/ISO_8601#Durations] for more information.
    # This method allows negative parts to be present in pattern.
    # If invalid string is provided, it will raise +ActiveSupport::Duration::ISO8601Parser::ParsingError+.
    def self.parse(iso8601duration)
      parts = ISO8601Parser.new(iso8601duration).parse!
      new(calculate_total_seconds(parts), parts)
    end

    def self.===(other) #:nodoc:
      other.is_a?(Duration)
    rescue ex
      false
    end

    def self.seconds(value) #:nodoc:
      new(value, { :seconds => value })
    end

    def self.minutes(value) #:nodoc:
      new(value * SECONDS_PER_MINUTE, { :minutes => value })
    end

    def self.hours(value) #:nodoc:
      new(value * SECONDS_PER_HOUR, { :hours => value })
    end

    def self.days(value) #:nodoc:

      new(value * SECONDS_PER_DAY, { :days => value })
    end

    def self.weeks(value) #:nodoc:
      new(value * SECONDS_PER_WEEK, { :weeks => value })
    end

    def self.months(value) #:nodoc:
      new(value * SECONDS_PER_MONTH, { :months => value })
    end

    def self.years(value) #:nodoc:
      new(value * SECONDS_PER_YEAR, { :years => value })
    end

    # Creates a new Duration from a seconds value that is converted
    # to the individual parts:
    #
    #   ActiveSupport::Duration.build(31556952).parts # => {:years=>1}
    #   ActiveSupport::Duration.build(2716146).parts  # => {:months=>1, :days=>1}
    #
    def self.build(value)
      parts = {} of Symbol => Int32
      remainder = value.to_f

      PARTS.each do |part|
        unless part == :seconds
          part_in_seconds = PARTS_IN_SECONDS[part]
          parts[part] = remainder.fdiv(part_in_seconds).to_i
          remainder = (remainder % part_in_seconds).round(9)
        end
      end

      parts[:seconds] = remainder.to_i
      parts.reject! { |k, v| v.zero? }

      new(value, parts)
    end

    private def self.calculate_total_seconds(parts)
      total = 0
      parts.each do |(key, value)|
        total += value * PARTS_IN_SECONDS[key]
      end
      total.to_i
    end

    def initialize(@value : Int32, @parts : Hash(Symbol, Int32))
    end

    def coerce(other) #:nodoc:
      if Scalar === other
        [other, self]
      else
        [Scalar.new(other), self]
      end
    end

    # Compares one Duration with another or a Numeric to this Duration.
    # Numeric values are treated as seconds.
    def <=>(other : Duration)
      if Duration === other
        @value <=> other.value
      elsif Numeric === other
        @value <=> other
      end
    end

    # Adds another Duration or a Numeric to this Duration. Numeric values
    # are treated as seconds.
    def +(other : Duration)
      if Duration === other
        parts = @parts.dup
        other.parts.each do |(key, value)|
          # TODO: Find another way to do this. Probably not efficient.
          parts = parts.merge({ key => value })
        end
        Duration.new(@value + other.value, parts)
      else
        seconds = @parts[:seconds] + other.to_i
        Duration.new(@value + other.value, @parts.merge({ :seconds => seconds }))
      end
    end

    # Subtracts another Duration or a Numeric from this Duration. Numeric
    # values are treated as seconds.
    def -(other)
      self + (-other)
    end

    # Multiplies this Duration by a Numeric and returns a new Duration.
    def *(other)
      if Scalar === other || Duration === other
        Duration.new(value * other.value, parts.map { |type, number| [type, number * other.value] })
      elsif Numeric === other
        Duration.new(value * other, parts.map { |type, number| [type, number * other] })
      else
        raise_type_error(other)
      end
    end

    # Divides this Duration by a Numeric and returns a new Duration.
    def /(other)
      if Scalar === other
        Duration.new(value / other.value, parts.map { |type, number| [type, number / other.value] })
      elsif Duration === other
        value / other.value
      elsif Numeric === other
        Duration.new(value / other, parts.map { |type, number| [type, number / other] })
      else
        raise_type_error(other)
      end
    end

    # Returns the modulo of this Duration by another Duration or Numeric.
    # Numeric values are treated as seconds.
    def %(other)
      if Duration === other || Scalar === other
        Duration.build(value % other.value)
      elsif Numeric === other
        Duration.build(value % other)
      else
        raise_type_error(other)
      end
    end

    def -
      Duration.new(-value, parts.map { |type, number| [type, -number] })
    end

    # def is_a?(klass) #:nodoc:
    #   Duration == klass || value.is_a?(klass)
    # end
    # alias :kind_of? :is_a?

    def instance_of?(klass) # :nodoc:
      Duration == klass || value.instance_of?(klass)
    end

    # Returns +true+ if +other+ is also a Duration instance with the
    # same +value+, or if <tt>other == value</tt>.
    def ==(other)
      if Duration === other
        other.value == value
      else
        other == value
      end
    end

    # Returns the amount of seconds a duration covers as a string.
    # For more information check to_i method.
    #
    #   1.day.to_s # => "86400"
    def to_s
      @value.to_s
    end

    # Returns the number of seconds that this Duration represents.
    #
    #   1.minute.to_i   # => 60
    #   1.hour.to_i     # => 3600
    #   1.day.to_i      # => 86400
    #
    # Note that this conversion makes some assumptions about the
    # duration of some periods, e.g. months are always 1/12 of year
    # and years are 365.2425 days:
    #
    #   # equivalent to (1.year / 12).to_i
    #   1.month.to_i    # => 2629746
    #
    #   # equivalent to 365.2425.days.to_i
    #   1.year.to_i     # => 31556952
    #
    # In such cases, Ruby's core
    # Date[http://ruby-doc.org/stdlib/libdoc/date/rdoc/Date.html] and
    # Time[http://ruby-doc.org/stdlib/libdoc/time/rdoc/Time.html] should be used for precision
    # date and time arithmetic.
    def to_i
      @value.to_i
    end

    # Returns +true+ if +other+ is also a Duration instance, which has the
    # same parts as this one.
    def eql?(other)
      Duration === other && other.value.eql?(value)
    end

    def hash
      @value.hash
    end

    # Calculates a new Time or Date that is as far in the future
    # as this Duration represents.
    def since(time = ::Time.current)
      sum(1, time)
    end
    # alias :from_now :since
    # alias :after :since

    # Calculates a new Time or Date that is as far in the past
    # as this Duration represents.
    def ago(time = ::Time.current)
      sum(-1, time)
    end
    # alias :until :ago
    # alias :before :ago

    def inspect #:nodoc:
      parts.
        reduce(::Hash(Symbol, Int32).new(0)) { |h, (l, r)| h[l] += r; h }.
        to_a.sort_by { |(k, v)| PARTS.index(k).not_nil! }.to_h.
        map     { |unit, val| "#{val} #{val == 1 ? unit.to_s.chomp : unit.to_s}" }.
        to_sentence(locale: I18n.default_locale)
    end

    def as_json(options = nil) #:nodoc:
      to_i
    end

    # Build ISO 8601 Duration string for this duration.
    # The +precision+ parameter can be used to limit seconds' precision of duration.
    def iso8601(precision : Int32? = nil)
      ISO8601Serializer.new(self, precision: precision).serialize
    end

    def sum(sign : Int32, time = ::Time.current)
      @parts.sum(time) do |t, (kind, number)|
        if kind == :seconds
          t.since(sign * number)
        elsif kind == :minutes
          t.since(sign * number * 60)
        elsif kind == :hours
          t.since(sign * number * 3600)
        else
          # t.advance(kind => sign * number)
        end
      end
    end

    private def method_missing(method, *args, &block)
      value.public_send(method, *args, &block)
    end

    forward_missing_to method_missing

    private def raise_type_error(other)
      raise TypeError.new "no implicit conversion of #{other.class} into #{self.class}"
    end
  end
end
