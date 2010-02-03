require 'active_support'

module Kasket
  autoload :ReadMixin, 'kasket/read_mixin'
  autoload :WriteMixin, 'kasket/write_mixin'
  autoload :DirtyMixin, 'kasket/dirty_mixin'
  autoload :QueryParser, 'kasket/query_parser'

  module ConfigurationMixin

    def without_kasket(&block)
      old_value = @use_kasket
      @use_kasket = false
      yield
    ensure
      @use_kasket = old_value
    end

    def use_kasket?
      @use_kasket == true
    end

    def kasket_parser
      @kasket_parser ||= QueryParser.new(self)
    end

    def kasket_key_prefix
      @kasket_key_prefix ||= "kasket-#{Kasket::Version::STRING}/#{table_name}/version=#{column_names.join.sum}/"
    end

    def kasket_key_for(attribute_value_pairs)
      kasket_key_prefix + attribute_value_pairs.map do |attribute, value|
        if (column = columns_hash[attribute.to_s]) && column.number?
          value = convert_number_column_value(value)
        end
        
        attribute.to_s + '=' + connection.quote(value, column)
      end.join('/')
    end

    def convert_number_column_value(value)
      if value == false
        0
      elsif value == true
        1
      elsif value.is_a?(String) && value.blank?
        nil
      else
        value
      end
    end

    def kasket_key_for_id(id)
      kasket_key_for([['id', id]])
    end

    def kasket_indices
      result = @kasket_indices || []
      result += superclass.kasket_indices unless self == ActiveRecord::Base
      result.uniq
    end

    def has_kasket_index_on?(sorted_attributes)
      kasket_indices.include?(sorted_attributes)
    end

    def has_kasket(options = {})
      has_kasket_on :id
    end

    def has_kasket_on(*args)
      @use_kasket = true
      attributes = args.sort! { |x, y| x.to_s <=> y.to_s }
      if attributes != [:id] && !kasket_indices.include?([:id])
        has_kasket_on(:id)
      end

      @kasket_indices ||= []
      @kasket_indices << attributes unless @kasket_indices.include?(attributes)

      include WriteMixin unless instance_methods.include?('store_in_kasket')
      extend DirtyMixin unless methods.include?('kasket_dirty_methods')
      extend ReadMixin unless methods.include?('find_by_sql_with_kasket')
    end
  end
end
