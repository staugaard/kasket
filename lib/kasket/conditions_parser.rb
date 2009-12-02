module Kasket
  class ConditionsParser
    # Examples:
    # SELECT * FROM `users` WHERE (`users`.`id` = 2) 
    # SELECT * FROM `users` WHERE (`users`.`id` = 2) LIMIT 1
    # 'SELECT * FROM \'posts\' WHERE (\'posts\'.\'id\' = 574019247) '
    TABLE_PATTERN       = /(?:`|")\w+(?:`|")/
    CONDITIONS_PATTERN  = /where \((.*)\)/i
    LIMIT_PATTERN       = /limit (1)/i
    
    SUPPORTED_QUERY_PATTERN = /^select \* from #{TABLE_PATTERN} #{CONDITIONS_PATTERN}(| #{LIMIT_PATTERN})\s*$/i 
   # SUPPORTED_QUERY_PATTERN = /^select \* from '\w+' #{CONDITIONS_PATTERN}(| #{LIMIT_PATTERN})\s*$/i 
    
    def initialize(model_class)
      @model_class = model_class
    end

    def attribute_value_pairs(sql)
      return unless support?(sql)
      
      conditions = extract_conditions(sql)
      if attributes = attributes_for_conditions(conditions)
        attributes.keys.sort.map { |attribute| [attribute.to_sym, attributes[attribute]] }
      end
    end
  
    def attributes_for_conditions(conditions)
      pairs = parse_indices_from_condition(conditions)

      return nil unless pairs

      pairs.inject({}) do |memo, pair|
        return nil if memo.has_key?(pair[0])
        memo[pair[0]] = pair[1]
        memo
      end
    end
    
    def extract_conditions(sql)
      sql =~ CONDITIONS_PATTERN
      $1
    end
    
    def extract_options(sql)
      sql =~ LIMIT_PATTERN
      { :limit => $1 }
    end
    
    def support?(sql)
      (sql =~ SUPPORTED_QUERY_PATTERN).present?
    end
    
    # SELECT * FROM `subscriptions` WHERE (`subscriptions`.account_id = 2) LIMIT 1
    
    AND = /\s+AND\s+/i
    TABLE_AND_COLUMN = /(?:(?:`|")?(\w+)(?:`|")?\.)?(?:`|")?(\w+)(?:`|")?/ # Matches: `users`.id, `users`.`id`, users.id, id
    VALUE = /'?(\d+|\?|(?:(?:[^']|'')*))'?/                     # Matches: 123, ?, '123', '12''3'
    KEY_EQ_VALUE = /^[\(\s]*#{TABLE_AND_COLUMN}\s+=\s+#{VALUE}[\)\s]*$/ # Matches: KEY = VALUE, (KEY = VALUE), ()(KEY = VALUE))

    def parse_indices_from_condition(conditions = '', *values)
      values = values.dup
      conditions.split(AND).inject([]) do |indices, condition|
        matched, table_name, column_name, sql_value = *(KEY_EQ_VALUE.match(condition))
        if matched
          value = sql_value == '?' ? values.shift : sql_value #@model_class.columns_hash[column_name].type_cast(sql_value)
          indices << [column_name, value]
        else
          return nil
        end
      end
    end
  end
end
