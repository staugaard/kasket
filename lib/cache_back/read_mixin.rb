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
        id_to_key_map = Hash[ids.uniq.map { |id| [id, cache_back_key_for(id)] }]
        cached_record_map = CacheBack.cache.get_multi(id_to_key_map.values)

        missing_keys = Hash[cached_record_map.select { |key, record| record.nil? }].keys

        return cached_record_map.values if missing_keys.empty?

        missing_ids = Hash[id_to_key_map.invert.select { |key, id| missing_keys.include?(key) }].values

        db_records = find_some_without_cache_back(missing_ids, options)
        db_records.each { |record| record.store_in_cache_back if record }

        (cached_record_map.values + db_records).compact.uniq.sort { |x, y| x.id <=> y.id}
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
