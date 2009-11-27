module CacheBack
  module ReadMixin

    def self.extended(model_class)
      class << model_class
        alias_method_chain :find_one, :cache_back
        alias_method_chain :find_some, :cache_back
      end
    end

    def find_one_with_cache_back(id, options)
      if cache_safe?(options)
        unless record = CacheBack.cache.read(cache_back_key_for(id))
          record = find_one_without_cache_back(id, options)
          record.store_in_cache_back if record
        end

        record
      else
        find_one_without_cache_back(id, options)
      end
    end

    def find_some_with_cache_back(ids, options)
      if cache_safe?(options)
        cached_records = ids.map { |id| CacheBack.cache.read(cache_back_key_for(id)) }.compact

        missing_ids = ids.map(&:to_i) - cached_records.map(&:id)

        return cached_records if missing_ids.empty?

        db_records = find_some_without_cache_back(missing_ids, options)
        db_records.each { |record| record.store_in_cache_back if record }

        (cached_records.compact + db_records.compact).sort { |x, y| x.id <=> y.id}
      else
        find_some_without_cache_back(ids, options)
      end
    end

    private

      def cache_safe?(options)
        options[:select].nil?
      end

  end
end
