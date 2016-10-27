class Hash
  def compact
    select { |_, value| !value.nil? }
  end

  def join(separator: ":")
    map{|k,v| "#{k}#{separator}#{v}"}
  end
end


class Array
  def nil_if_empty
    if empty?
      return nil
    else
      return self
    end
  end
end
