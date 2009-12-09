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
        if value = Kasket.cache.read(query[:key])
          Array.wrap(value).collect! { |record| instantiate(record.clone) }
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
          Kasket.cache.write(key, records.first.instance_variable_get(:@attributes))
        else
          keys = records.map do |record|
            key = kasket_key_for_id(record.id)
            Kasket.cache.write(key, record.instance_variable_get(:@attributes))
            key
          end
          Kasket.cache.write(key, keys)
        end
        records
      end

  end
end
