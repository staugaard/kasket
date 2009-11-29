require 'rubygems'
require 'active_record'
require 'active_support'

require 'cache_back/configuration_mixin'
require 'cache_back/reload_association_mixin'
require 'cache_back/cache'
require 'cache_back/rack_middleware'

module CacheBack
  CONFIGURATION = {:max_collection_size => 100}

  module_function

  def cache
    Thread.current["cache_back_cache"] ||= Cache.new
  end

  def setup(options = {})
    CONFIGURATION[:max_collection_size] = options[:max_collection_size] if options[:max_collection_size]

    ActiveRecord::Base.extend(CacheBack::ConfigurationMixin)
    ActiveRecord::Associations::BelongsToAssociation.send(:include, CacheBack::ReloadAssociationMixin)
    ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, CacheBack::ReloadAssociationMixin)
    ActiveRecord::Associations::HasOneThroughAssociation.send(:include, CacheBack::ReloadAssociationMixin)

    #sets up local cache clearing after each request
    begin
      ApplicationController.after_filter do
        CacheBack.cache.reset!
      end
    rescue NameError => e

    end

    #sets up local cache clearing after each test case
    begin
      ActiveSupport::TestCase.class_eval do
        setup :clear_cache
        def clear_cache
          CacheBack.cache.reset!
          Rails.cache.clear if Rails.cache.respond_to?(:clear)
        end
      end
    rescue NameError => e
    end
  end
end
