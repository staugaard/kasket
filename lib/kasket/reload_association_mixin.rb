module Kasket
  module ReloadAssociationMixin
    def reload_with_kasket_clearing(*args)
      if loaded?
        clear_local_kasket_indices if respond_to?(:clear_local_kasket_indices)
      else
        target_class = proxy_reflection.options[:polymorphic] ? association_class : proxy_reflection.klass
        Kasket.cache.delete_matched_local(/^#{target_class.kasket_key_prefix}/) if target_class.respond_to?(:kasket_key_prefix)
      end

      reload_without_kasket_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :kasket_clearing
    end
  end
end
