module CacheBack
  class Cache
    def initialize
      reset!
    end

    def read(*args)
      result = @local_cache[args[0]] || Rails.cache.read(*args)
      if result.is_a?(CachedModel)
        result = result.instanciate_model
      elsif result.is_a?(Array)
        models = get_multi(result)
        result = result.map { |key| models[key]}
      end

      @local_cache[args[0]] = result if result
      result
    end

    def get_multi(keys)
      map = Hash[keys.zip(keys.map { |key| @local_cache[key] })]
      missing_keys = map.select { |key, value| value.nil? }.map(&:first)

      unless missing_keys.empty?
        if Rails.cache.respond_to?(:read_multi)
          missing_map = Rails.cache.read_multi(missing_keys)
          missing_map.each do |key, value|
            value = value.instanciate_model if value.is_a?(CachedModel)
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

    def write(*args)
      @local_cache[args[0]] = args[1]

      if args[1].is_a?(ActiveRecord::Base)
        args[1] = CachedModel.new(args[1])
      end

      Rails.cache.write(*args)
    end

    def delete(*args)
      @local_cache.delete(args[0])
      Rails.cache.delete(*args)
    end

    def reset!
      @local_cache = {}
    end

    class CachedModel
      def initialize(model)
        @name = model.class.name
        @attributes = model.instance_variable_get(:@attributes)
      end

      def instanciate_model
        @name.constantize.send(:instantiate, @attributes)
      end
    end
  end
end
