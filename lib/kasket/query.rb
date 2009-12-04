module Kasket
  autoload :Parser, 'kasket/query/parser'
  
  class Query
    module CacheKey
        
      def collection_key
        if cachable?
          collection_key = @model.kasket_key_for(attribute_value_pairs)
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
    end
    
    def limit
      parser.extract_options(@sql)[:limit]
    end
    
    def attribute_value_pairs
      parser.attribute_value_pairs(@sql) || '' # FIXME
    end
    
    protected
    
    def parser
      @model.kasket_parser
    end
    
  end
end