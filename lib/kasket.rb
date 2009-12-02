require 'rubygems'
require 'active_record'
require 'active_support'

require 'kasket/active_record_patches'
require 'kasket/configuration_mixin'
require 'kasket/reload_association_mixin'
require 'kasket/cache'
require 'kasket/query'

module Kasket
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

    #sets up local cache clearing after each request
    begin
      ApplicationController.after_filter do
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

