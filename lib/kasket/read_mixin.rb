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
        Kasket.cache.read(key) || Kasket.cache.write(key, find_by_sql_without_kasket(sql))
      else
        find_by_sql_without_kasket(sql)
      end
    end
    
  end
end