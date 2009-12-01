require 'active_support'
require 'zlib'

module Kasket
  autoload :ReadMixin, 'kasket/read_mixin'
  autoload :WriteMixin, 'kasket/write_mixin'
  autoload :DirtyMixin, 'kasket/dirty_mixin'

  module ConfigurationMixin
    def kasket_key_prefix
      @kasket_key_prefix ||= "kasket/#{table_name}/version=#{Zlib.crc32(column_names.sort.join)}/"
    end

    def kasket_key_for(attribute_value_pairs)
      kasket_key_prefix + attribute_value_pairs.map {|attribute, value| attribute.to_s + '=' + value.to_s}.join('/')
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
      attributes = args.sort! { |x, y| x.to_s <=> y.to_s }
      if attributes != [:id] && !kasket_indices.include?([:id])
        has_kasket_on(:id)
      end

      @kasket_indices ||= []
      @kasket_indices << attributes unless @kasket_indices.include?(attributes)

      include WriteMixin unless instance_methods.include?('store_in_kasket')
      extend ReadMixin unless methods.include?('without_kasket')
      extend DirtyMixin unless methods.include?('kasket_dirty_methods')
    end
  end
end