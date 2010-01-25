module Kasket
  module ReloadAssociationMixin
    # TODO write tests for this
    def reload_with_kasket_clearing(*args)
      if loaded?
        Kasket.clear_local if target.class.include?(WriteMixin)
      else
        target_class = proxy_reflection.options[:polymorphic] ? association_class : proxy_reflection.klass
        Kasket.clear_local if target_class.include?(WriteMixin)
      end

      reload_without_kasket_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :kasket_clearing
    end
  end
end
