require 'helper'

class QueryTest < ActiveSupport::TestCase
  Post.has_kasket

  context "converting a query to cache keys" do
    setup do
      @sql   = "SELECT * FROM `apples` WHERE (id = 1 AND color = red AND size = big)"
      @query = Query.new(@sql, Post)
    end

    should "extract conditions" do
      assert_equal [[:color, "red"], [:size, "big"]], @query.attribute_value_pairs
    end
    
    should "provide its limit" do
      assert_equal nil, Query.new(@sql, Post).limit
      
      assert_equal 1, Query.new(@sql += ' LIMIT 1', Post).limit
    end
  
    context "caching" do
      
      should "provide records" do
        assert_equal [], @query.records
        
        Kasket.cache.write(@query.collection_key, 'hello')
        assert_equal [ 'hello' ], @query.records
      end
      
      should "write records to the cache" do
        post = Post.new(:title => 'hello')
        @query.records = [ post ]
        assert_equal post.attributes, @query.records.first.attributes
      end

      should "correctly determine if its cacheable" do
        assert_equal true, @query.cachable?
      end

      should "locate indexed conditions" do
        assert_equal true, @query.indexes?
      end
      
      should "provide index candidates" do
        assert_equal [:color, :id, :size], @query.index_candidates
      end

      should "generate a collection keyt" do
        assert_equal "kasket/posts/version=3558/color=red/size=big", @query.collection_key  
        query_with_limit = Query.new(@sql += ' LIMIT 1', Post)
        assert_equal "kasket/posts/version=3558/color=red/size=big/first", query_with_limit.collection_key      
      end

    end
  
  end
  


end
