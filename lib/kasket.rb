# -*- encoding: utf-8 -*-
require 'active_record'
require 'active_support'

require 'kasket/active_record_patches'

module Kasket
  autoload :ConfigurationMixin, 'kasket/configuration_mixin'
  autoload :ReloadAssociationMixin, 'kasket/reload_association_mixin'
  autoload :Query, 'kasket/query'

  CONFIGURATION = {:max_collection_size => 100}

  class Version
    MAJOR = 1
    MINOR = 0
    PATCH = 2
    STRING = "#{MAJOR}.#{MINOR}.#{PATCH}"
  end

  module_function

  def setup(options = {})
    return if ActiveRecord::Base.extended_by.member?(Kasket::ConfigurationMixin)

    CONFIGURATION[:max_collection_size] = options[:max_collection_size] if options[:max_collection_size]

    ActiveRecord::Base.extend(Kasket::ConfigurationMixin)
    ActiveRecord::Associations::BelongsToAssociation.send(:include, Kasket::ReloadAssociationMixin)
    ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, Kasket::ReloadAssociationMixin)
    ActiveRecord::Associations::HasOneThroughAssociation.send(:include, Kasket::ReloadAssociationMixin)
  end

  def self.cache_store=(options)
    @cache_store = ActiveSupport::Cache.lookup_store(options)
  end

  def self.cache
    @cache_store ||= Rails.cache
  end

  def clear_local
    if Kasket.cache.respond_to?(:with_local_cache)
      Kasket.cache.send(:local_cache).try(:clear)
    end
  end
end

