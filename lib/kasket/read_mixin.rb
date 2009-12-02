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
    
    def find_by_sql_with_kasket(sql)
      query = Query.new(sql, self)
      if query.records.present?
        query.records
      else
        records = find_by_sql_without_kasket(sql)
        query.records = records
        records
      end
    end
    
    def use_kasket?
      @use_kasket != false
    end
             
  end
end
