module CacheBack
  module ReloadAssociationMixin
    def reload_with_cache_back_clearing(*args)
      # TODO we could calculate the right key to clear by parsing the association conditions.
      # this would clear less keys, and we would not have to load the target
      load_target
      target.clear_local_cache_back_indices if target.respond_to?(:clear_local_cache_back_indices)
      reload_without_cache_back_clearing(*args)
    end

    def self.included(base)
      base.alias_method_chain :reload, :cache_back_clearing
    end
  end
end