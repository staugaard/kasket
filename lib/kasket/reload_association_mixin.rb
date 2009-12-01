module Kasket
  module ReloadAssociationMixin
    def reload_with_kasket_clearing(*args)
      # TODO we could calculate the right key to clear by parsing the association conditions.
      # this would clear less keys
      Kasket.cache.reset!
      reload_without_kasket_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :kasket_clearing
    end
  end
end