require 'rubygems'
require 'activerecord'

require 'cache_back/configuration_mixin'
require 'cache_back/cache'
require 'cache_back/rack_middleware'

module CacheBack
  module_function

  def cache
    Thread.current["cache_back_cache"] ||= Cache.new
  end
end

ActiveRecord::Base.extend(CacheBack::ConfigurationMixin)

begin
  ActionController::Dispatcher.middleware.use(CacheBack::RackMiddleware)
rescue NameError => e
  
end

