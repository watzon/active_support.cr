class String
  # Returns the string, first removing all whitespace on both ends of
  # the string, and then changing remaining consecutive whitespace
  # groups into one space each.
  #
  # Note that it handles both ASCII and Unicode whitespace.
  #
  #   %{ Multi-line
  #      string }.squish                   # => "Multi-line string"
  #   " foo   bar    \n   \t   boo".squish # => "foo bar boo"
  def squish
    res = gsub(/[[:space:]]+/, " ")
    res = res.strip
    res
  end

  # Alters the string by removing all occurrences of the patterns.
  #   str = "foo bar test"
  #   str.remove(" test", /bar/)          # => "foo "
  #   str                                 # => "foo "
  def remove(*patterns)
    res = self
    patterns.each do |pattern|
      res = res.gsub pattern, ""
    end
    res
  end

  # Truncates a given +text+ after a given <tt>size</tt> if +text+ is longer than <tt>size</tt>:
  #
  #   "Once upon a time in a world far far away".truncate(27)
  #   # => "Once upon a time in a wo..."
  #
  # Pass a string or regexp <tt>:separator</tt> to truncate +text+ at a natural break:
  #
  #   "Once upon a time in a world far far away".truncate(27, separator: " ")
  #   # => "Once upon a time in a..."
  #
  #   "Once upon a time in a world far far away".truncate(27, separator: /\s/)
  #   # => "Once upon a time in a..."
  #
  # The last characters will be replaced with the <tt>:omission</tt> string (defaults to "...")
  # for a total length not exceeding <tt>size</tt>:
  #
  #   "And they found that many people were sleeping better.".truncate(25, omission: "... (continued)")
  #   # => "And they f... (continued)"
  def truncate(truncate_at, omission = "...", separator : (String? | Regex?) = nil)
    return dup unless size > truncate_at

    length_with_room_for_omission = truncate_at - omission.size
    stop = \
      if separator
        rindex(separator, length_with_room_for_omission) || length_with_room_for_omission
      else
        length_with_room_for_omission
      end

    "#{self[0, stop]}#{omission}"
  end

  # Truncates a given +text+ after a given number of words (<tt>words_count</tt>):
  #
  #   "Once upon a time in a world far far away".truncate_words(4)
  #   # => "Once upon a time..."
  #
  # Pass a string or regexp <tt>:separator</tt> to specify a different separator of words:
  #
  #   "Once<br>upon<br>a<br>time<br>in<br>a<br>world".truncate_words(5, separator: "<br>")
  #   # => "Once<br>upon<br>a<br>time<br>in..."
  #
  # The last characters will be replaced with the <tt>:omission</tt> string (defaults to "..."):
  #
  #   "And they found that many people were sleeping better.".truncate_words(5, omission: "... (continued)")
  #   # => "And they found that many... (continued)"
  def truncate_words(words_count, omission = "...", separator : (String | Regex) = " ")
    separator = Regex.new(separator) unless separator.is_a?(Regex)
    if self =~ /\A((?>.+?#{separator}){#{words_count - 1}}.+?)#{separator}.*/m
      $1 + (omission)
    else
      dup
    end
  end
end
