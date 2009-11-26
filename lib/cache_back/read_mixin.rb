module CacheBack
  module ReadMixin

    def self.extended(model_class)
      class << model_class
        alias_method_chain :find_one, :cache_back
      end
    end

    def find_one_with_cache_back(id, options)
      record = cache_safe?(options) ? CacheBack.cache.read(cache_back_key_for(id)) : nil

      if record.nil?
        record = find_one_without_cache_back(id, options)
        record.store_in_cache_back if record
      end

      record
    end

    private

      def cache_safe?(options)
        !options.has_key?(:select)
      end

  end
end
