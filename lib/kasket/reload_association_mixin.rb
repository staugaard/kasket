# -*- encoding: utf-8 -*-
module Kasket
  module ReloadAssociationMixin
    def reload_with_kasket_clearing(*args)
      if loaded?
        Kasket.clear_local if target.class.include?(WriteMixin)
      else
        refl = respond_to?(:reflection) ? reflection : proxy_reflection
        target_class = (refl.options[:polymorphic] ? (respond_to?(:klass) ? klass : association_class) : refl.klass)
        Kasket.clear_local if target_class && target_class.include?(WriteMixin)
      end

      reload_without_kasket_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :kasket_clearing
    end
  end
end
