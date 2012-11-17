require 'rubygems'

require 'bundler'
Bundler.setup
Bundler.require(:default, :development)

if defined?(Debugger)
  ::Debugger.start
  ::Debugger.settings[:autoeval] = true if ::Debugger.respond_to?(:settings)
end

require 'test/unit'
require 'active_record/fixtures'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'kasket'

Kasket.setup

require 'shoulda'

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

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

ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(ActiveSupport::TestCase.fixture_path)

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
