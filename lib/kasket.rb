require 'rubygems'
require 'active_record'
require 'active_support'

require 'kasket/active_record_patches'

module Kasket
  autoload :Cache, 'kasket/cache'
  autoload :ConfigurationMixin, 'kasket/configuration_mixin'
  autoload :ReloadAssociationMixin, 'kasket/reload_association_mixin'
  autoload :RackMiddleware, 'kasket/rack_middleware'

  CONFIGURATION = {:max_collection_size => 100}

  module_function

  def cache
    Thread.current["kasket_cache"] ||= Cache.new
  end

  def setup(options = {})
    CONFIGURATION[:max_collection_size] = options[:max_collection_size] if options[:max_collection_size]

    ActiveRecord::Base.extend(Kasket::ConfigurationMixin)
    ActiveRecord::Associations::BelongsToAssociation.send(:include, Kasket::ReloadAssociationMixin)
    ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, Kasket::ReloadAssociationMixin)
    ActiveRecord::Associations::HasOneThroughAssociation.send(:include, Kasket::ReloadAssociationMixin)

    #sets up local cache clearing on rack
    begin
      ActionController::Dispatcher.middleware.use(Kasket::RackMiddleware)
    rescue NameError => e
      puts('WARNING: The kasket rack middleware is not in your rack stack')
    end

    #sets up local cache clearing before each request.
    #this is done to make it work for non rack rails and for functional tests
    begin
      ApplicationController.before_filter do
        Kasket.cache.clear_local
      end
    rescue NameError => e
    end

    #sets up local cache clearing after each test case
    begin
      ActiveSupport::TestCase.class_eval do
        setup :clear_cache
        def clear_cache
          Kasket.cache.clear_local
          Rails.cache.clear if Rails.cache.respond_to?(:clear)
        end
      end
    rescue NameError => e
    end
  end
end
