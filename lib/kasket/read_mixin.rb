module Kasket
  module ReadMixin

    def self.extended(base)
      class << base
        alias_method_chain :find_by_sql, :kasket
      end
    end

    def find_by_sql_with_kasket(sql)
      query = kasket_parser.parse(sanitize_sql(sql)) if use_kasket?
      if query && has_kasket_index_on?(query[:index])
        if query[:key].is_a?(Array)
          find_by_sql_with_kasket_on_id_array(sql, query)
        else
          if value = Kasket.cache.read(query[:key])
            Array.wrap(value).collect { |record| instantiate(record.dup) }
          else
            store_in_kasket(query[:key], find_by_sql_without_kasket(sql))
          end
        end
      else
        find_by_sql_without_kasket(sql)
      end
    end

    def find_by_sql_with_kasket_on_id_array(sql, query)
      key_value_map = Kasket.cache.read_multi(*query[:key])
      missing_ids = []

      query[:key].each do |key|
        if value = key_value_map[key]
          key_value_map[key] = instantiate(value.dup)
        else
          missing_ids << key.split('=').last.to_i
        end
      end

      without_kasket do
        find(missing_ids).each do |instance|
          instance.store_in_kasket
          key_value_map[instance.kasket_key] = instance
        end
      end

      key_value_map.values
    end

    protected

      def store_in_kasket(key, records)
        if records.size == 1
          Kasket.cache.write(key, records.first.instance_variable_get(:@attributes).dup)
        elsif records.size <= Kasket::CONFIGURATION[:max_collection_size]
          instance_keys = records.map do |record|
            instance_key = kasket_key_for_id(record.id)
            Kasket.cache.write(instance_key, record.instance_variable_get(:@attributes).dup)
            instance_key
          end

          Kasket.cache.write(key, instance_keys) if key.is_a?(String)
        end
        records
      end

  end
end

