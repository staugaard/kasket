module Kasket
  class Parser
    # Examples:
    # SELECT * FROM `users` WHERE (`users`.`id` = 2) 
    # SELECT * FROM `users` WHERE (`users`.`id` = 2) LIMIT 1
    # 'SELECT * FROM \'posts\' WHERE (\'posts\'.\'id\' = 574019247) '
    CONDITIONS_PATTERN  = /where \((.*)\)/i
    LIMIT_PATTERN       = /limit 1/i
        
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
      limit = (sql =~ LIMIT_PATTERN) ? 1 : nil
      { :limit => limit }
    end
    
    def support?(sql)
      (sql =~ supported_query_pattern).present?
    end
    
    protected
    
    def supported_query_pattern
      @supported_query_pattern ||= /^select \* from (?:`|")#{@model_class.table_name}(?:`|") #{CONDITIONS_PATTERN}(| #{LIMIT_PATTERN})\s*$/i 
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
          value = sql_value == '?' ? values.shift : sql_value
          indices << [column_name, value]
        else
          return nil
        end
      end
    end
    
  end
end
