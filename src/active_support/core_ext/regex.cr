class Regex
  def multiline?
    options & MULTILINE == MULTILINE
  end

  def match?(string, pos = 0)
    !!match(string, pos)
  end
end
