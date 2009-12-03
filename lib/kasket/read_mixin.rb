module Kasket
  module ReadMixin

    def self.extended(model_class)
      class << model_class
       # alias_method_chain :find_some, :kasket unless methods.include?('find_some_without_kasket')
        alias_method_chain :find_by_sql, :kasket unless methods.include?('find_by_sql_without_kasket')
      end
    end

    def without_kasket(&block)
      old_value = @use_kasket || true
      @use_kasket = false
      yield
    ensure
      @use_kasket = old_value
    end
    
    def use_kasket?
      @use_kasket != false
    end
    
    def find_by_sql_with_kasket(sql)
      query = Query.new(sql, self)
      load_records(query) || cache_records(query, find_by_sql_without_kasket(sql))
    end
    
    protected
    
    def load_records(query)
      key = query.collection_key
      if key && records = Kasket.cache.read(key)
        Array(records)
      end
    end
    
    def cache_records(query, records)
      if records.size == 1
        Kasket.cache.write(query.collection_key, records[0])
      elsif records.size <= Kasket::CONFIGURATION[:max_collection_size]
        records.each { |record| record.store_in_kasket if record }
        Kasket.cache.write(query.collection_key, records.map(&:kasket_key))
      end
      records
    end
             
  end
end
