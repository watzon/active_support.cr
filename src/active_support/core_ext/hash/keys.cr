class Hash(K, V)
  # Returns a new hash with all keys converted using the +block+ operation.
  #
  #  hash = { :name => "Rob", :age => "28" }
  #
  #  hash.transform_keys { |key| key.to_s.upcase } # => {"NAME" => "Rob", "AGE" => "28"}
  #
  # If you do not provide a +block+, it will return an Enumerator
  # for chaining with other methods:
  #
  #  hash.transform_keys.with_index { |k, i| [k, i].join } # => {"name0"=>"Rob", "age1"=>"28"}
  def transform_keys
    result = {} of typeof(yield(keys.first)) => V
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end

  def transform_keys(hash)
    result = hash
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end

  # Destructively converts all keys using the +block+ operations.
  # Same as +transform_keys+ but modifies +self+.
  def transform_keys!
    keys.each do |key|
      self[yield(key)] = delete(key)
    end
    self
  end

  # Returns a new hash with all keys converted to strings.
  #
  #   hash = { :name => "Rob", :age => "28" }
  #
  #   hash.stringify_keys
  #   # => {"name" => "Rob", "age" => "28"}
  def stringify_keys
    transform_keys(&.to_s)
  end

  # Destructively converts all keys to strings. Same as
  # +stringify_keys+, but modifies +self+.
  def stringify_keys!
    transform_keys!(&.to_s)
  end

  # Validates all keys in a hash match <tt>*valid_keys</tt>, raising
  # +ArgumentError+ on a mismatch.
  #
  # Note that keys are treated differently than HashWithIndifferentAccess,
  # meaning that string and symbol keys will not match.
  #
  #   { name: 'Rob', years: '28' }.assert_valid_keys(:name, :age) # => raises "ArgumentError: Unknown key: :years. Valid keys are: :name, :age"
  #   { :name => "Rob", :age => "28" }.assert_valid_keys('name', 'age') # => raises "ArgumentError: Unknown key: :name. Valid keys are: 'name', 'age'"
  #   { :name => "Rob", :age => "28" }.assert_valid_keys(:name, :age)   # => passes, raises nothing
  def assert_valid_keys(*valid_keys)
    valid_keys.flatten!
    each_key do |k|
      unless valid_keys.include?(k)
        raise ArgumentError.new("Unknown key: #{k.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(", ")}")
      end
    end
  end

  # Returns a new hash with all keys converted by the block operation.
  # This includes the keys from the root hash and from all
  # nested hashes and arrays.
  #
  #  hash = { person: { :name => "Rob", :age => "28" } }
  #
  #  hash.deep_transform_keys{ |key| key.to_s.upcase }
  #  # => {"PERSON"=>{"NAME" => "Rob", "AGE" => "28"}}
  def deep_transform_keys(&block)
    _deep_transform_keys_in_object(self, &block)
  end

  # Destructively converts all keys by using the block operation.
  # This includes the keys from the root hash and from all
  # nested hashes and arrays.
  def deep_transform_keys!(&block)
    _deep_transform_keys_in_object!(self, &block)
  end

  # Returns a new hash with all keys converted to strings.
  # This includes the keys from the root hash and from all
  # nested hashes and arrays.
  #
  #   hash = { person: { :name => "Rob", :age => "28" } }
  #
  #   hash.deep_stringify_keys
  #   # => {"person"=>{"name" => "Rob", "age" => "28"}}
  def deep_stringify_keys
    deep_transform_keys(&.to_s)
  end

  # Destructively converts all keys to strings.
  # This includes the keys from the root hash and from all
  # nested hashes and arrays.
  def deep_stringify_keys!
    deep_transform_keys!(&.to_s)
  end

  # support methods for deep transforming nested hashes and arrays
  private def _deep_transform_keys_in_object(object, &block)
    case object
    when Hash
      object.each_with_object({} of typeof(yield(keys.first)) => V) do |(key, value), result|
        result[yield(key)] = _deep_transform_keys_in_object(value, &block)
      end
    when Array
      object.map { |e| _deep_transform_keys_in_object(e, &block) }
    else
      object
    end
  end

  private def _deep_transform_keys_in_object!(object, &block)
    case object
    when Hash
      object.keys.each do |key|
        value = object.delete(key)
        object[yield(key)] = _deep_transform_keys_in_object!(value, &block)
      end
      object
    when Array
      object.map! { |e| _deep_transform_keys_in_object!(e, &block) }
    else
      object
    end
  end
end

# hash = { :name => "Rob", :age => "28" }
# puts hash.stringify_keys
