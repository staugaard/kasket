require 'kasket/conditions_parser'

module Kasket
  module ReadMixin

    def self.extended(model_class)
      class << model_class
        alias_method_chain :find_some, :kasket unless methods.include?('find_some_without_kasket')
        alias_method_chain :find_every, :kasket unless methods.include?('find_every_without_kasket')
      end
    end

    def without_kasket(&block)
      old_value = @use_kasket || true
      @use_kasket = false
      yield
    ensure
      @use_kasket = old_value
    end

    def find_every_with_kasket(options)
      attribute_value_pairs = kasket_conditions_parser.attribute_value_pairs(options) if cache_safe?(options)

      limit = (options[:limit] || (scope(:find) || {})[:limit])

      if (limit.nil? || limit == 1) && attribute_value_pairs && has_kasket_index_on?(attribute_value_pairs.map(&:first))
        collection_key = kasket_key_for(attribute_value_pairs)
        collection_key << '/first' if limit == 1
        unless records = Kasket.cache.read(collection_key)
          records = without_kasket do
            find_every_without_kasket(options)
          end

          if records.size == 1
            Kasket.cache.write(collection_key, records[0])
          elsif records.size <= Kasket::CONFIGURATION[:max_collection_size]
            records.each { |record| record.store_in_kasket if record }
            Kasket.cache.write(collection_key, records.map(&:kasket_key))
          end
        end

        Array(records)
      else
        without_kasket do
          find_every_without_kasket(options)
        end
      end
    end

    def find_some_with_kasket(ids, options)
      attribute_value_pairs = kasket_conditions_parser.attribute_value_pairs(options) if cache_safe?(options)
      attribute_value_pairs << [:id, ids] if attribute_value_pairs

      limit = (options[:limit] || (scope(:find) || {})[:limit])

      if limit.nil? && attribute_value_pairs && has_kasket_index_on?(attribute_value_pairs.map(&:first))
        id_to_key_map = Hash[ids.uniq.map { |id| [id, kasket_key_for_id(id)] }]
        cached_record_map = Kasket.cache.get_multi(id_to_key_map.values)

        missing_keys = Hash[cached_record_map.select { |key, record| record.nil? }].keys

        return cached_record_map.values if missing_keys.empty?

        missing_ids = Hash[id_to_key_map.invert.select { |key, id| missing_keys.include?(key) }].values

        db_records = without_kasket do
          find_some_without_kasket(missing_ids, options)
        end
        db_records.each { |record| record.store_in_kasket if record }

        (cached_record_map.values + db_records).compact.uniq.sort { |x, y| x.id <=> y.id}
      else
        without_kasket do
          find_some_without_kasket(ids, options)
        end
      end
    end

    private

      def cache_safe?(options)
        @use_kasket != false && [options, scope(:find) || {}].all? do |hash|
          result = hash[:select].nil? && hash[:joins].nil? && hash[:order].nil? && hash[:offset].nil?
          result && (options[:limit].nil? || options[:limit] == 1)
        end
      end

      def kasket_conditions_parser
        @kasket_conditions_parser ||= Kasket::ConditionsParser.new(self)
      end
  end
end
