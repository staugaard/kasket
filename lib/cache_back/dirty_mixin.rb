module CacheBack
  module DirtyMixin
    def cache_back_dirty_methods(*method_names)
      method_names.each do |method|
        unless method_defined?("without_cache_back_update_#{method}")
          alias_method("without_cache_back_update_#{method}", method)
          define_method(method) do |*args|
            result = send("without_cache_back_update_#{method}", *args)
            clear_cache_back_indices
            result
          end
        end
      end
    end
  end
end