require 'kasket/conditions_parser'

module Kasket
  class Query
    
    module Caching
      # Depends on
      ## Kasket.cache
      ## Kasket::Configuration
      ## record#store_in_kasket
      ## model.kasket_cache_enabled?
      #
      ## attribute_value_pairs
      ## indexable?
      
      # def multi_records
      #   segment, ids = extract_ids(attribute_value_pairs)
      #   
      #   id_to_key_map = Hash[ids.uniq.map { |id| [id, kasket_key_for_id(id)] }]
      # 
      #   cached_record_map = Kasket.cache.get_multi(id_to_key_map.values)
      #   
      #   missing_keys = Hash[cached_record_map.select { |key, record| record.nil? }].keys
      #   
      #   return cached_record_map.values if missing_keys.empty?
      #   
      #   missing_ids = Hash[id_to_key_map.invert.select { |key, id| missing_keys.include?(key) }].values
      #   
      #   db_records = without_kasket do
      #     @model.find_by_sql_without_kasket(@sql.sub(segment, ids.to_s(:db)))
      #   end
      #   db_records.each { |record| record.store_in_kasket if record }
      #   
      #   (cached_record_map.values + db_records).compact.uniq.sort { |x, y| x.id <=> y.id}
      # end    
      
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
        true#@model.use_kasket?
      end
      
    end
    include Caching
  
    def initialize(sql, model)
      @sql   = sql
      @model = model
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
      @parser ||= Kasket::ConditionsParser.new(@model)
    end
    
  end
end