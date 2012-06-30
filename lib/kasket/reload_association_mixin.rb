# -*- encoding: utf-8 -*-
module Kasket
  module ReloadAssociationMixin
    def reload_with_kasket_clearing(*args)
      Kasket.clear_local if klass.include?(WriteMixin)
      reload_without_kasket_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :kasket_clearing unless base.include?(self)
    end
  end
end
