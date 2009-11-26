require 'rubygems'
require 'activerecord'

require 'cache_back/configuration_mixin'
require 'cache_back/cache'

module CacheBack
  module_function

  def cache
    Thread.current["cache_back_cache"] ||= Cache.new
  end
end

ActiveRecord::Base.extend(CacheBack::ConfigurationMixin)
ActionController::Dispatcher.middleware.use(CacheBack::Middleware)
