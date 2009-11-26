module CacheBack
  module WriteMixin
    def shallow_clone
      clone = self.class.new
      clone.instance_variable_set("@attributes", instance_variable_get(:@attributes))
      clone.instance_variable_set("@new_record", new_record?)
      clone
    end

    def cache_back_key
      @cache_back_key ||= new_record? ? nil : self.class.cache_back_key_for(id)
    end

    def store_in_cache_back
      if !readonly? && cache_back_key
        CacheBack.cache.write(cache_back_key, shallow_clone, self.class.inherited_cache_back_options)
      end
    end

    def remove_from_cache_back
      CacheBack.cache.delete(cache_back_key) if cache_back_key
    end

    def self.included(model_class)
      model_class.after_save :store_in_cache_back
      model_class.after_destroy :remove_from_cache_back
    end
  end
end
