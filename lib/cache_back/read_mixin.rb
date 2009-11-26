module CacheBack
  module ReadMixin

    def self.extended(model_class)
      class << model_class
        alias_method_chain :find_one, :cache_back
      end
    end

    def find_one_with_cache_back(id, options)
      record = CacheBack.cache.read(cache_back_key_for(id))

      unless record
        record = find_one_without_cache_back(id, options)
        record.store_in_cache_back if record
      end

      record
    end

  end
end
