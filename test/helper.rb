require 'rubygems'
require 'test/unit'
require 'mocha'
require 'shoulda'
require 'active_support'
require 'active_record'
require 'active_record/fixtures'

ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection('test')
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

load(File.dirname(__FILE__) + "/schema.rb")

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'kasket'

Kasket.setup

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  fixtures :all

  #setup :clear_cache

  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  def clear_cache
    Kasket.cache.reset!
    Rails.cache.clear
  end
end

ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(ActiveSupport::TestCase.fixture_path)

module Rails
  module_function
  CACHE = ActiveSupport::Cache::MemoryStore.new

  def cache
    CACHE
  end
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many :comments

  def make_dirty!
    self.updated_at = Time.now
    self.connection.execute("UPDATE posts SET updated_at = '#{updated_at.utc.to_s(:db)}' WHERE id = #{id}")
  end
end

class Blog < ActiveRecord::Base
  has_many :posts
end
