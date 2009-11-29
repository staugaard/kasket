require 'active_support'

module CacheBack
  autoload :ReadMixin, 'cache_back/read_mixin'
  autoload :WriteMixin, 'cache_back/write_mixin'
  autoload :DirtyMixin, 'cache_back/dirty_mixin'

  module ConfigurationMixin
    def cache_back_version(version)
      @cache_back_version = version.to_s
    end

    def inherited_cache_back_version
      if self == ActiveRecord::Base
        @cache_back_version
      else
        @cache_back_version ||= superclass.inherited_cache_back_version
      end
    end

    def inherited_cache_back_options
      if self == ActiveRecord::Base
        @cache_back_option
      else
        @cache_back_option ||= superclass.inherited_cache_back_options
      end
    end

    def cache_back_key_for(attribute_value_pairs)
      key = "cache_back/#{table_name}/version=#{inherited_cache_back_version}"
      attribute_value_pairs.each do |attribute, value|
        key << "/#{attribute}="
        if value.is_a?(Array)
          key << value.join(',')
        else
          key << value.to_s
        end
      end
      key
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
      options = args.extract_options!
      attributes = args.sort! { |x, y| x.to_s <=> y.to_s }

      @cache_back_version ||= options.delete(:version) || '1'
      @cache_back_option ||= options

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