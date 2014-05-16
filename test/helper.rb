require 'bundler/setup'
require 'test/unit'
require 'shoulda/context'
require 'mocha/setup'
require 'active_record'
require 'logger'

ENV['TZ'] = 'UTC'
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.logger = Logger.new(StringIO.new)

require 'active_record/fixtures'
require 'kasket'

Kasket.setup

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  fixtures :all

  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  self.use_transactional_fixtures = true

  self.use_instantiated_fixtures  = false

  setup :clear_cache
  def clear_cache
    Kasket.cache.clear
  end
end

module Rails
  module_function
  CACHE = ActiveSupport::Cache::MemoryStore.new
  LOGGER = Logger.new(STDOUT)

  def cache
    CACHE
  end

  def logger
    LOGGER
  end
end

require 'test_models'
POST_VERSION = Post.column_names.join.sum
COMMENT_VERSION = Comment.column_names.join.sum
