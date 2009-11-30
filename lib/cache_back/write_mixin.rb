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
      def cache_back_key
        @cache_back_key ||= new_record? ? nil : self.class.cache_back_key_for_id(id)
      end

      def store_in_cache_back
        if !readonly? && cache_back_key
          CacheBack.cache.write(cache_back_key, self, self.class.inherited_cache_back_options)
        end
      end

      def cache_back_keys
        new_attributes = attributes.symbolize_keys

        old_attributes = Hash[changes.map {|attribute, values| [attribute, values[0]]}].symbolize_keys
        old_attributes.reverse_merge!(new_attributes)

        keys = []
        self.class.cache_back_indices.each do |index|
          old_key = self.class.cache_back_key_for(index.map { |attribute| [attribute, old_attributes[attribute]]})
          new_key = self.class.cache_back_key_for(index.map { |attribute| [attribute, new_attributes[attribute]]})

          [old_key, new_key].uniq.each do |key|
            keys << key
            keys << "#{key}/first"
          end
        end
        keys
      end

      def clear_cache_back_indices
        cache_back_keys.each do |key|
          CacheBack.cache.delete(key)
        end
      end

      def clear_local_cache_back_indices
        cache_back_keys.each do |key|
          CacheBack.cache.delete_local(key)
        end
      end

      def reload_with_cache_back_clearing(*args)
        clear_local_cache_back_indices
        reload_without_cache_back_clearing(*args)
      end
    end

    def self.included(model_class)
      model_class.extend         ClassMethods
      model_class.send :include, InstanceMethods

      model_class.after_save :clear_cache_back_indices
      model_class.after_destroy :clear_cache_back_indices

      model_class.alias_method_chain :reload, :cache_back_clearing

      class << model_class
        alias_method_chain :update_counters, :cache_back_clearing
      end
    end
  end
end
