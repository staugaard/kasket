require 'active_support'
require 'zlib'

module CacheBack
  autoload :ReadMixin, 'cache_back/read_mixin'
  autoload :WriteMixin, 'cache_back/write_mixin'
  autoload :DirtyMixin, 'cache_back/dirty_mixin'

  module ConfigurationMixin
    def cache_back_key_prefix
      @cache_back_key_prefix ||= "cache_back/#{table_name}/version=#{Zlib.crc32(column_names.sort.join)}/"
    end

    def cache_back_key_for(attribute_value_pairs)
      cache_back_key_prefix + attribute_value_pairs.map {|attribute, value| attribute.to_s + '=' + value.to_s}.join('/')
    end

    def cache_back_key_for_id(id)
      cache_back_key_for([['id', id]])
    end

    def cache_back_indices
      result = @cache_back_indices || []
      result += superclass.cache_back_indices unless self == ActiveRecord::Base
      result.uniq
    end

    def has_cache_back_index_on?(sorted_attributes)
      cache_back_indices.include?(sorted_attributes)
    end

    def has_cache_back(options = {})
      has_cache_back_on :id
    end

    def has_cache_back_on(*args)
      attributes = args.sort! { |x, y| x.to_s <=> y.to_s }
      if attributes != [:id] && !cache_back_indices.include?([:id])
        has_cache_back_on(:id)
      end

      @cache_back_indices ||= []
      @cache_back_indices << attributes unless @cache_back_indices.include?(attributes)

      include WriteMixin unless instance_methods.include?('store_in_cache_back')
      extend ReadMixin unless methods.include?('without_cache_back')
      extend DirtyMixin unless methods.include?('cache_back_dirty_methods')
    end
  end
end