module Kasket
  class Cache
    module Local
      
      attr_accessor :enable_local
      
      def enable_local?
        @enable_local == true
      end
      
      def enable_local=(enable)
        @enable_local = enable
        clear_local unless enable_local == true
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
      
      def delete(key)
        @local_cache.delete(key)
        super
      end
      
      def write(key, value)
        if enable_local? && storable?(value)
          @local_cache[key] = value.duplicable? ? value.dup : value
        end
        super
      end
      
      def read(*args)
        if result = @local_cache[args[0]] 
          if result.is_a?(Array) && result.first.is_a?(String)
            models = get_multi(result)
            result = result.map { |key| models[key] }
          end

          @local_cache[args[0]] = result if result
          result
        else
          super
        end
      end
      
      def get_multi(keys)
        map = Hash[*keys.zip(keys.map { |key| @local_cache[key] }).flatten]
        missing_keys = map.select { |key, value| value.nil? }.map(&:first)

        unless missing_keys.empty?
          missing_map = super(missing_keys) 
          missing_map.each do |key, value|
            map[key] = @local_cache[key] = value
          end
        end
        
        map
      end
      
    end # end LocalCache
    
    def initialize
      extend Local
      clear_local
    end

    def read(*args)
      result = Rails.cache.read(*args)
      if result.is_a?(Array) && result.first.is_a?(String)
        models = get_multi(result)
        result = result.map { |key| models[key] }
      end

      result
    end

    def get_multi(keys)
      if Rails.cache.respond_to?(:read_multi)
        Rails.cache.read_multi(keys)
      else
        map = {}
        keys.each { |key| map[key] = read(key) }
        map
      end
    end
    
    def write(key, value)
      if storable?(value)
        Rails.cache.write(key, value.duplicable? ? value.dup : value) # Fix due to Rails.cache freezing values in 2.3.4
      end
      value
    end

    def delete(*args)
      Rails.cache.delete(*args)
    end

    protected

      def storable?(value)
        !value.is_a?(Array) || value.size <= Kasket::CONFIGURATION[:max_collection_size]
      end

  end
end
