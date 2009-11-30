module CacheBack
  class ConditionsParser
    def initialize(model_class)
      @model_class = model_class
    end

    def attribute_value_pairs(options)
      #pulls out the conditions from each hash
      condition_fragments = [options[:conditions]]

      #add the scope to the mix
      if scope = @model_class.send(:scope, :find)
        condition_fragments << scope[:conditions]
      end

      #add the type if we are on STI
      condition_fragments << {:type => @model_class.name} if @model_class.finder_needs_type_condition?

      condition_fragments.compact!

      #parses each conditions fragment but bails if one of the did not parse
      attributes_fragments = condition_fragments.map do |condition_fragment|
        attributes_fragment = attributes_for_conditions(condition_fragment)
        return nil unless attributes_fragment
        attributes_fragment
      end

      #merges the hashes but bails if there is an overlap
      attributes = attributes_fragments.inject({}) do |memo, attributes_fragment|
        attributes_fragment.each do |attribute, value|
          return nil if memo.has_key?(attribute)
          memo[attribute] = value
        end
        memo
      end

      attributes.keys.sort.map { |attribute| [attribute.to_sym, attributes[attribute]] }
    end

    def attributes_for_conditions(conditions)
      pairs = case conditions
        when Hash
          return conditions.stringify_keys
        when String
          parse_indices_from_condition(conditions)
        when Array
          parse_indices_from_condition(*conditions)
        when NilClass
          []
      end

      return nil unless pairs

      pairs.inject({}) do |memo, pair|
        return nil if memo.has_key?(pair[0])
        memo[pair[0]] = pair[1]
        memo
      end
    end

    AND = /\s+AND\s+/i
    TABLE_AND_COLUMN = /(?:(?:`|")?(\w+)(?:`|")?\.)?(?:`|")?(\w+)(?:`|")?/ # Matches: `users`.id, `users`.`id`, users.id, id
    VALUE = /'?(\d+|\?|(?:(?:[^']|'')*))'?/                     # Matches: 123, ?, '123', '12''3'
    KEY_EQ_VALUE = /^[\(\s]*#{TABLE_AND_COLUMN}\s+=\s+#{VALUE}[\)\s]*$/ # Matches: KEY = VALUE, (KEY = VALUE), ()(KEY = VALUE))

    def parse_indices_from_condition(conditions = '', *values)
      values = values.dup
      conditions.split(AND).inject([]) do |indices, condition|
        matched, table_name, column_name, sql_value = *(KEY_EQ_VALUE.match(condition))
        if matched
          value = sql_value == '?' ? values.shift : @model_class.columns_hash[column_name].type_cast(sql_value)
          indices << [column_name, value]
        else
          return nil
        end
      end
    end
  end
end
