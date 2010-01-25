module Kasket
  module ReadMixin

    def self.extended(base)
      class << base
        alias_method_chain :find_by_sql, :kasket
      end
    end

    def find_by_sql_with_kasket(sql)
      sql = sanitize_sql(sql)
      query = kasket_parser.parse(sql) if use_kasket?
      if query && has_kasket_index_on?(query[:index])

        if value = Rails.cache.read(query[:key])
          Array.wrap(value).collect! { |record| instantiate(record.dup) }
        else
          store_in_kasket(query[:key], find_by_sql_without_kasket(sql))
        end
      else
        find_by_sql_without_kasket(sql)
      end
    end

    protected

      def store_in_kasket(key, records)
        if records.size == 1
          Rails.cache.write(key, records.first.instance_variable_get(:@attributes).dup)
        elsif records.size <= Kasket::CONFIGURATION[:max_collection_size]
          keys = records.map do |record|
            key = kasket_key_for_id(record.id)
            Rails.cache.write(key, record.instance_variable_get(:@attributes).dup)
            key
          end
          Rails.cache.write(key, keys)
        end
        records
      end

  end
end
