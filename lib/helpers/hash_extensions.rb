class Hash
  def compact_recursive(hash = self)
    select { |_, value| !value.nil? }

    def handle_item(item)
      case item
        when Symbol
          item.to_s
        when Hash
          compact_recursive(item)
        when Array
          item.map { |v| handle_item(v) } unless item.empty?
        else
          item
      end
    end

    {}.tap do |h|
      hash.each do |key, value|
        value = handle_item(value) unless value.nil?
        h[key] = handle_item(value) if value
      end
    end
  end

  def join(separator: ":")
    map{|k,v| "#{k}#{separator}#{v}"}
  end

  def symbolize_recursive(hash = self)
    {}.tap do |h|
      hash.each { |key, value| h[key.to_sym] = map_value(value) }
    end
  end

  def map_value(thing)
    case thing
      when Hash
        symbolize_recursive(thing)
      when Array
        thing.map { |v| map_value(v) }
      else
        thing
    end
  end
end
