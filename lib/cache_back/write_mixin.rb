module CacheBack
  module WriteMixin
    module ClassMethods
      def remove_from_cache_back(ids)
        Array(ids).each do |id|
          CacheBack.cache.delete(cache_back_key_for_id(id))
        end
      end

      def update_counters_with_cache_back_clearing(*args)
        remove_from_cache_back(args[0])
        update_counters_without_cache_back_clearing(*args)
      end
    end

    module InstanceMethods
      def shallow_clone
        clone = self.class.new
        clone.instance_variable_set("@attributes", instance_variable_get(:@attributes))
        clone.instance_variable_set("@new_record", new_record?)
        clone
      end

      def cache_back_key
        @cache_back_key ||= new_record? ? nil : self.class.cache_back_key_for_id(id)
      end

      def store_in_cache_back
        if !readonly? && cache_back_key
          CacheBack.cache.write(cache_back_key, shallow_clone, self.class.inherited_cache_back_options)
        end
      end

      def remove_from_cache_back
        CacheBack.cache.delete(cache_back_key) if cache_back_key
      end

      def reload_with_cache_back_clearing(*args)
        remove_from_cache_back
        reload_without_cache_back_clearing(*args)
      end
    end

    def self.included(model_class)
      model_class.extend         ClassMethods
      model_class.send :include, InstanceMethods

      #model_class.after_save :store_in_cache_back
      model_class.after_update :remove_from_cache_back
      model_class.after_destroy :remove_from_cache_back
      model_class.alias_method_chain :reload, :cache_back_clearing

      class << model_class
        alias_method_chain :update_counters, :cache_back_clearing
      end
    end
  end
end
