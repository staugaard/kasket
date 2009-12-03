module Kasket
  module QueryCache
    # Note: Causes logger to lie about calculation time if it's hitting memcached
    
    def self.extended(base)
      base.instance_eval do
        @query_cache = Kasket.cache
      end
    end
    
    def clear_query_cache
      @query_cache.clear_local if @query_cache
    end

  end
end
