module Kasket
  autoload :Parser, 'kasket/query/parser'
  
  class Query < String

    module CacheKey
        
      def collection_key
        if cachable?
          collection_key = @model.kasket_key_for(attribute_value_pairs || '')
          collection_key << '/first' if limit == 1
          collection_key
        end
      end
      
      def cachable?
        cache_enabled? && indexes?
      end
      
      def indexes?
        index_candidates.any? { |key| @model.kasket_indices.include?([key]) }
      end
      
      def index_candidates
        attribute_value_pairs ? attribute_value_pairs.map(&:first) : []
      end
      
      protected
      
      def cache_enabled?
        @model.use_kasket?
      end
      
    end
    include CacheKey
  
    def initialize(sql, model)
      @sql   = sql
      @model = model
      super(sql)
    end
    
    def limit
      limit = parser.extract_options(@sql)[:limit]
      limit.to_i if limit
    end
    
    def attribute_value_pairs
      parser.attribute_value_pairs(@sql)
    end
    
    protected
    
    def parser
      @parser ||= Kasket::Parser.new(@model)
    end
    
  end
end