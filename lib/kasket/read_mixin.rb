module Kasket  
  module ReadMixin
    
    def self.extended(base)
      class << base
        alias_method_chain :find_by_sql, :kasket
      end
    end
    
    def find_by_sql_with_kasket(sql)
      key = Kasket::Query.new(sql, self).collection_key
      if key
        if value = Kasket.cache.read(key)
          Array.wrap(value).collect! { |record| instantiate(record.clone) }
        else
          store_in_kasket(key, find_by_sql_without_kasket(sql))
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