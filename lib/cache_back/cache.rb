module CacheBack
  class Cache
    def initialize
      reset!
    end

    def read(*args)
      @local_cache[args[0]] ||= Rails.cache.read(*args)
    end

    def write(*args)
      @local_cache[args[0]] = args[1]
      Rails.cache.write(*args)
    end

    def reset!
      @local_cache = {}
    end
  end
end