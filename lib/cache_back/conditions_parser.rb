module CacheBack
  class ConditionsParser
    def initialize(model_class)
      @model_class = model_class
    end

    def attribute_value_pairs(options, scope)
      from_scope = attribute_value_pairs_for_conditions((scope || {})[:conditions])
      return nil unless from_scope

      from_options = attribute_value_pairs_for_conditions(options[:conditions])
      return nil unless from_options

      pairs = from_scope.inject(from_options) do |memo, pair|
        attribute = pair[0]
        if memo_pair = memo.find{ |p| p[0] == attribute}
          memo_pair[0] = Array(memo_pair[0])
          memo_pair[0] << pair[1]
        else
          memo << pair
        end
      end

      pairs.sort! { |pair1, pair2| pair1[0] <=> pair2[0] }

      pairs.map do |attribute, value|
        if value.is_a?(Array)
          value.flatten!
          if value.size == 1
            [attribute.to_sym, value[0]]
          else
            [attribute.to_sym, value]
          end
        else
          [attribute.to_sym, value]
        end
      end
    end

    def attribute_value_pairs_for_conditions(conditions)
      case conditions
      when Hash
        conditions.to_a.collect { |key, value| [key.to_s, value] }
      when String
        parse_indices_from_condition(conditions)
      when Array
        parse_indices_from_condition(*conditions)
      when NilClass
        []
      end
    end

    AND = /\s+AND\s+/i
    TABLE_AND_COLUMN = /(?:(?:`|")?(\w+)(?:`|")?\.)?(?:`|")?(\w+)(?:`|")?/ # Matches: `users`.id, `users`.`id`, users.id, id
    VALUE = /'?(\d+|\?|(?:(?:[^']|'')*))'?/                     # Matches: 123, ?, '123', '12''3'
    KEY_EQ_VALUE = /^\(?#{TABLE_AND_COLUMN}\s+=\s+#{VALUE}\)?$/ # Matches: KEY = VALUE, (KEY = VALUE)
    ORDER = /^#{TABLE_AND_COLUMN}\s*(ASC|DESC)?$/i              # Matches: COLUMN ASC, COLUMN DESC, COLUMN

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