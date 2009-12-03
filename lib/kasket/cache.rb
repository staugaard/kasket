module Kasket
  class Cache
    module LocalCache
      
      def initialize
        clear_local
      end
      
      def read(*args)
        @local_cache[args[0]] ||= super 
      end
      
      def write(*args)
        @local_cache[args[0]] = args[1]
        super
      end
      
      def delete(*args)
        @local_cache.delete(args[0])
        super
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
      
    end

    def initialize
      extend LocalCache
    end

    def [](key)
      read(key)
    end
    
    def []=(key, records)
      write(key, records)
    end
    
    def has_key?(key)
      read(key).present?
    end
    
    def delete(key)
      Rails.cache.delete(key.collection_key) if kasket?(key)
    end
        
    def read(key)
      Rails.cache.read(key.collection_key) if kasket?(key)
    end
    
    def write(key, value)
      if kasket?(key) && value.size <= Kasket::CONFIGURATION[:max_collection_size]
        Rails.cache.write(key.collection_key, value)
      end
      value
    end
    
    protected

    def kasket?(key)
      key.respond_to?(:collection_key) && key.collection_key.present?
    end

  end
end
