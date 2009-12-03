require 'helper'

class QueryTest < ActiveSupport::TestCase
  Post.has_kasket_on :color

  context "converting a query to cache keys" do
    setup do
      @sql   = "SELECT * FROM `apples` WHERE (color = red AND size = big)"
      @query = Kasket::Query.new(@sql, Post)
    end

    should "extract conditions" do
      assert_equal [[:color, "red"], [:size, "big"]], @query.attribute_value_pairs
    end
    
    should "provide its limit" do
      assert_equal nil, Kasket::Query.new(@sql, Post).limit
      
      assert_equal 1, Kasket::Query.new(@sql += ' LIMIT 1', Post).limit
    end
  
    context "caching" do

      should "correctly determine if its cacheable" do
        assert_equal true, @query.cachable?
      end

      should "locate indexed conditions" do
        assert_equal true, @query.indexes?
      end
      
      should "provide index candidates" do
        assert_equal [:color, :size], @query.index_candidates
      end

      should "generate a collection keyt" do
        assert_equal "kasket/posts/version=3558/color=red/size=big", @query.collection_key  
        query_with_limit = Kasket::Query.new(@sql += ' LIMIT 1', Post)
        assert_equal "kasket/posts/version=3558/color=red/size=big/first", query_with_limit.collection_key      
      end

    end
  
  end

end
