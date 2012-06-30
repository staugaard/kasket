# -*- encoding: utf-8 -*-
require 'active_record'
require 'active_support'

require 'kasket/version'

module Kasket
  autoload :ReadMixin,              'kasket/read_mixin'
  autoload :WriteMixin,             'kasket/write_mixin'
  autoload :DirtyMixin,             'kasket/dirty_mixin'
  autoload :QueryParser,            'kasket/query_parser'
  autoload :ConfigurationMixin,     'kasket/configuration_mixin'
  autoload :ReloadAssociationMixin, 'kasket/reload_association_mixin'
  autoload :Query,                  'kasket/query'
  autoload :Visitor,                'kasket/visitor'
  autoload :SelectManagerMixin,     'kasket/select_manager_mixin'
  autoload :RelationMixin,          'kasket/relation_mixin'

  CONFIGURATION = {:max_collection_size => 100}

  module_function

  def setup(options = {})
    return if ActiveRecord::Base.respond_to?(:has_kasket)

    CONFIGURATION[:max_collection_size] = options[:max_collection_size] if options[:max_collection_size]

    ActiveRecord::Base.extend(Kasket::ConfigurationMixin)

    if defined?(ActiveRecord::Relation)
      ActiveRecord::Relation.send(:include, Kasket::RelationMixin)
      Arel::SelectManager.send(:include, Kasket::SelectManagerMixin)
    end

    ActiveRecord::Associations::BelongsToAssociation.send(:include, Kasket::ReloadAssociationMixin)
    if ActiveRecord::VERSION::MAJOR == 2
      ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, Kasket::ReloadAssociationMixin)
    end
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
