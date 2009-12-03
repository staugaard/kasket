require 'helper'

class QueryTest < ActiveSupport::TestCase
  Post.has_kasket
 
  context "find by sql with kasket" do
    setup do
      @database_results = [ { 'id' => 1, 'title' => 'Hello' }, { 'id' => 2, 'title' => 'World' }]
      Post.stubs(:find_by_sql_without_kasket).returns(@database_results)
    end
    
    should "handle unsupported sql" do
      assert_equal @database_results, Post.find_by_sql_with_kasket('select unsupported sql statement')
      assert Kasket.cache.local.empty?
    end
    
    should "read results" do
      Kasket.cache.write('kasket/posts/version=3558/id=1', @database_results.first)
      assert_equal [ @database_results.first ], Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)'), Kasket.cache.inspect
    end
    
    should "store uncached results in kasket" do
      Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)')
      
      assert_equal @database_results.first, Kasket.cache.read('kasket/posts/version=3558/id=1'), Kasket.cache.inspect
    end
    
  end

end

