require 'rubygems'
require 'active_record'
require 'active_support'

require 'kasket/active_record_patches'

module Kasket
  autoload :ConfigurationMixin, 'kasket/configuration_mixin'
  autoload :ReloadAssociationMixin, 'kasket/reload_association_mixin'
  autoload :RackMiddleware, 'kasket/rack_middleware'
  autoload :Query, 'kasket/query'

  CONFIGURATION = {:max_collection_size => 100}

  class Version
    MAJOR = 0
    MINOR = 7
    PATCH = 4
    STRING = "#{MAJOR}.#{MINOR}.#{PATCH}"
  end

  module_function

  def setup(options = {})
    CONFIGURATION[:max_collection_size] = options[:max_collection_size] if options[:max_collection_size]

    ActiveRecord::Base.extend(Kasket::ConfigurationMixin)
    ActiveRecord::Associations::BelongsToAssociation.send(:include, Kasket::ReloadAssociationMixin)
    ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, Kasket::ReloadAssociationMixin)
    ActiveRecord::Associations::HasOneThroughAssociation.send(:include, Kasket::ReloadAssociationMixin)
  end

  def clear_local
    if Rails.cache.respond_to?(:with_local_cache)
      Rails.cache.send(:local_cache).try(:clear)
    end
  end
end
