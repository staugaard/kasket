module CacheBack
  class Cache
    def initialize
      reset!
    end

    def read(*args)
      @local_cache[args[0]] ||= Rails.cache.read(*args)
    end

    def get_multi(keys)
      map = Hash[keys.zip(keys.map { |key| @local_cache[key] })]
      missing_keys = map.select { |key, value| value.nil? }.map(&:first)

      unless missing_keys.empty?
        if Rails.cache.respond_to?(:read_multi)
          missing_map = Rails.cache.read_multi(missing_keys)
          missing_map.each do |key, value|
            @local_cache[key] = value
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

    def write(*args)
      @local_cache[args[0]] = args[1]
      Rails.cache.write(*args)
    end

    def delete(*args)
      @local_cache.delete(args[0])
      Rails.cache.delete(*args)
    end

    def reset!
      @local_cache = {}
    end
  end
end
