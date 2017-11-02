require "./core_ext/string/inquiry"

module ActiveSupport
  # Wrapping a string in this class gives you a prettier way to test
  # for equality. The value returned by <tt>Rails.env</tt> is wrapped
  # in a StringInquirer object, so instead of calling this:
  #
  #   Rails.env == "production"
  #
  # you can call this:
  #
  #   Rails.env.production?
  #
  # == Instantiating a new StringInquirer
  #
  #   vehicle = ActiveSupport::StringInquirer.new("car")
  #   vehicle.car?   # => true
  #   vehicle.bike?  # => false
  class StringInquirer
    # :nodoc:
    property wrapped : String

    # Wraps the provided string
    def initialize(@wrapped)
    end

    # :nodoc:
    private def test(string)
      wrapped == string
    end

    # Inspects the provided call name and raises if the call name does not finish in '?'.
    macro method_missing(call)
      {% if call.name.ends_with?('?') %}
        test({{call.name.id.stringify}}.chomp('?'))
      {% else %}
        super
      {% end %}
    end
  end
end
