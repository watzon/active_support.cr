require "uri"

class Object
  # Alias of <tt>to_s</tt>.
  def to_param
    to_s
  end

  # Converts an object into a string suitable for use as a URL query string,
  # using the given <tt>key</tt> as the param name.
  def to_query(key, space_to_plus = false)
    "#{URI.escape(key.to_param)}=#{URI.escape(to_param.to_s, space_to_plus)}"
  end
end

struct Nil
  # Returns +self+.
  def to_param
    self
  end
end

struct Bool
  # Returns +self+.
  def to_param
    self
  end
end

class Array
  # Calls <tt>to_param</tt> on all its elements and joins the result with
  # slashes. This is used by <tt>url_for</tt> in Action Pack.
  def to_param
    map(&.to_param).join "/"
  end

  # Converts an array into a string suitable for use as a URL query string,
  # using the given +key+ as the param name.
  #
  #   ['Rails', 'coding'].to_query('hobbies') # => "hobbies%5B%5D=Rails&hobbies%5B%5D=coding"
  def to_query(key, space_to_plus = false)
    prefix = "#{key}[]"

    if empty?
      nil.to_query(prefix)
    else
      URI.escape(prefix) + "=" + map! { |v| URI.escape(v, space_to_plus) }.join("&")
    end
  end
end

struct NamedTuple
  def to_query(namespace = nil, space_to_plus = false)
    query = [] of String
    each do |key, value|
      query.push value.to_query(namespace ? "#{namespace}[#{key}]" : key, space_to_plus)
    end
    query.join("&")
  end
end

class Hash(K, V)
  # Returns a string representation of the receiver suitable for use as a URL
  # query string:
  #
  #   {name: 'David', nationality: 'Danish'}.to_query
  #   # => "name=David&nationality=Danish"
  #
  # An optional namespace can be passed to enclose key names:
  #
  #   {name: 'David', nationality: 'Danish'}.to_query('user')
  #   # => "user%5Bname%5D=David&user%5Bnationality%5D=Danish"
  #
  # The string pairs "key=value" that conform the query string
  # are sorted lexicographically in ascending order.
  #
  # This method is also aliased as +to_param+.
  def to_query(namespace = nil, space_to_plus = false)
    query = [] of String
    each do |key, value|
      unless (value.is_a?(Hash) || value.is_a?(Array)) && value.empty?
        query.push value.to_query(namespace ? "#{namespace}[#{key}]" : key, space_to_plus)
      end
    end
    query.join("&")
  end
end
