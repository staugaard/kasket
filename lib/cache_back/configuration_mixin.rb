require 'activesupport'

module CacheBack
  autoload :ReadMixin, 'cache_back/read_mixin'
  autoload :WriteMixin, 'cache_back/write_mixin'

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

    def cache_back_key_for(id)
      "cache_back/#{name}/version_#{inherited_cache_back_version}/#{id}"
    end

    def has_cache_back(options = {})
      @cache_back_version = options.delete(:version) || '1'
      @cache_back_option = options

      include WriteMixin unless instance_methods.include?('store_in_cache_back')
      extend ReadMixin unless method_defined?(:find_one_with_cache_back!)
    end
  end
end