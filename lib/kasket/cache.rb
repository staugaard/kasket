module Kasket
  class Cache
    def initialize
      clear_local
    end
 
    def read(*args)
      result = @local_cache[args[0]] || Rails.cache.read(*args)
      if result.is_a?(Array) && result.first.is_a?(String)
        models = get_multi(result)
        result = result.map { |key| models[key] }
      end

      @local_cache[args[0]] = result if result
      result
    end
 
    def get_multi(keys)
      map = Hash[*keys.zip(keys.map { |key| @local_cache[key] }).flatten]
      missing_keys = map.select { |key, value| value.nil? }.map(&:first)
 
      unless missing_keys.empty?
        if Rails.cache.respond_to?(:read_multi)
          missing_map = Rails.cache.read_multi(missing_keys)
          missing_map.each do |key, value|
            missing_map[key] = @local_cache[key] = value
          end
          map.merge!(missing_map)
        else
          missing_keys.each do |key|
            map[key] = read(key)
          end
        end
      end
 
      map
    end
 
    def write(key, value)
      if storable?(value)
        @local_cache[key] = value.duplicable? ? value.dup : value
        Rails.cache.write(key, value.duplicable? ? value.dup : value) # Fix due to Rails.cache freezing values in 2.3.4
      end
      value
    end
 
    def delete(*args)
      @local_cache.delete(args[0])
      Rails.cache.delete(*args)
    end
 
    def delete_local(*keys)
      keys.each do |key|
        @local_cache.delete(key)
      end
    end
 
    def delete_matched_local(matcher)
      @local_cache.delete_if { |k,v| k =~ matcher }
    end
 
    def clear_local
      @local_cache = {}
    end
    
    def local
      @local_cache
    end
    
    protected
    
    def storable?(value)
      !value.is_a?(Array) || value.size <= Kasket::CONFIGURATION[:max_collection_size]
    end
 
  end
end
