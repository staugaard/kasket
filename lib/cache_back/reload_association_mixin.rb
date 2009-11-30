module CacheBack
  module ReloadAssociationMixin
    def reload_with_cache_back_clearing(*args)
      # TODO we could calculate the right key to clear by parsing the association conditions.
      # this would clear less keys
      CacheBack.cache.reset!
      reload_without_cache_back_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :cache_back_clearing
    end
  end
end