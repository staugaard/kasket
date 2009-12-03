module Kasket  
  module WriteMixin
    
    module ClassMethods
      def remove_from_kasket(ids)
        Array(ids).each do |id|
          Kasket.cache.delete(kasket_key_for_id(id))
        end
      end

      def update_counters_with_kasket_clearing(*args)
        remove_from_kasket(args[0])
        update_counters_without_kasket_clearing(*args)
      end
    end

    module InstanceMethods
      def kasket_key
        @kasket_key ||= new_record? ? nil : self.class.kasket_key_for_id(id)
      end

      def store_in_kasket
        if !readonly? && kasket_key
          Kasket.cache.write(kasket_key, self)
        end
      end

      def kasket_keys
        attribute_sets = [attributes.symbolize_keys]

        if changed?
          old_attributes = Hash[*changes.map {|attribute, values| [attribute, values[0]]}.flatten].symbolize_keys
          attribute_sets << old_attributes.reverse_merge(attribute_sets[0])
        end

        keys = []
        self.class.kasket_indices.each do |index|
          keys += attribute_sets.map do |attribute_set|
            self.class.kasket_key_for(index.map { |attribute| [attribute, attribute_set[attribute]]})
          end
        end

        keys.uniq!
        keys.map! {|key| [key, "#{key}/first"]}
        keys.flatten!
      end

      def clear_kasket_indices
        kasket_keys.each do |key|
          Kasket.cache.delete(key)
        end
      end

      def clear_local_kasket_indices
        kasket_keys.each do |key|
          Kasket.cache.delete_local(key)
        end
      end

      def reload_with_kasket_clearing(*args)
        clear_local_kasket_indices
        reload_without_kasket_clearing(*args)
      end
    end

    def self.included(model_class)
      model_class.extend         ClassMethods
      model_class.send :include, InstanceMethods

      model_class.after_save :clear_kasket_indices
      model_class.after_destroy :clear_kasket_indices

      model_class.alias_method_chain :reload, :kasket_clearing
      
      class << model_class
        alias_method_chain :update_counters, :kasket_clearing
      end
    end
  end
end
