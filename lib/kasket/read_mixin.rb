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
        Array(Kasket.cache.read(key) || store_in_kasket(key, find_by_sql_without_kasket(sql)))
      else
        find_by_sql_without_kasket(sql)
      end
    end
    
    protected
    
    def store_in_kasket(key, records)
      if records.size == 1
        Kasket.cache.write(key, records.first)
      else
        keys = records.map do |record| 
          key = kasket_key_for_id(record[primary_key])
          Kasket.cache.write(key, record)
        end  
        Kasket.cache.write(key, keys)
      end
      records
    end
    
  end
end