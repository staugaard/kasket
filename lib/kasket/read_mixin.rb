# -*- encoding: utf-8 -*-
module Kasket
  module ReadMixin

    def self.extended(base)
      class << base
        alias_method_chain :find_by_sql, :kasket
      end
    end

    def find_by_sql_with_kasket(*args)
      sql = args[0]

      if use_kasket?
        if sql.respond_to?(:to_kasket_query)
          query = sql.to_kasket_query(self, args[1])
        else
          query = kasket_parser.parse(sanitize_sql(sql))
        end
      end

      if query && has_kasket_index_on?(query[:index])
        if query[:key].is_a?(Array)
          find_by_sql_with_kasket_on_id_array(query[:key])
        else
          if value = Kasket.cache.read(query[:key])
            if value.is_a?(Array)
              find_by_sql_with_kasket_on_id_array(value)
            else
              Array.wrap(value).collect { |record| instantiate(record.dup) }
            end
          else
            store_in_kasket(query[:key], find_by_sql_without_kasket(*args))
          end
        end
      else
        find_by_sql_without_kasket(*args)
      end
    end

    def find_by_sql_with_kasket_on_id_array(keys)
      key_attributes_map = Kasket.cache.read_multi(*keys)

      found_keys, missing_keys = keys.partition{|k| key_attributes_map[k] }
      found_keys.each{|k| key_attributes_map[k] = instantiate(key_attributes_map[k].dup) }
      key_attributes_map.merge!(missing_records_from_db(missing_keys))

      key_attributes_map.values.compact
    end

    protected

      def missing_records_from_db(missing_keys)
        return {} if missing_keys.empty?

        id_key_map = Hash[missing_keys.map{|key| [key.split('=').last.to_i, key] }]

        found = without_kasket { find_all_by_id(id_key_map.keys) }
        found.each(&:store_in_kasket)
        Hash[found.map{|record| [id_key_map[record.id], record] }]
      end

      def store_in_kasket(key, records)
        if records.size == 1
          if records.first.kasket_cacheable?
            Kasket.cache.write(key, records.first.attributes_before_type_cast.dup)
          end
        elsif records.empty?
          ActiveRecord::Base.logger.info("[KASKET] would have stored an empty resultset") if ActiveRecord::Base.logger
        elsif records.size <= Kasket::CONFIGURATION[:max_collection_size]
          if records.all?(&:kasket_cacheable?)
            instance_keys = records.map do |record|
              instance_key = kasket_key_for_id(record.id)
              Kasket.cache.write(instance_key, record.attributes_before_type_cast.dup)
              instance_key
            end

            Kasket.cache.write(key, instance_keys) if key.is_a?(String)
          end
        end
        records
      end

  end
end
