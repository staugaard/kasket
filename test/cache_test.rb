require 'helper'

class CacheTest < ActiveSupport::TestCase

  context "Cache" do
    setup do
      @cache = Kasket::Cache.new
    end

    context "reading" do
      
      should "work with non collection values" do
        @cache.write('key', 'value')
        assert_equal 'value', @cache.read('key')
      end
      
      should "fetch original results of stored collections" do
        @cache.write('key1', 'value1')
        @cache.write('key2', 'value2')
        @cache.write('key3', 'value3')
        @cache.write('collection_key', [ 'key1', 'key2', 'key3'])
        
        assert_equal [ 'value1', 'value2', 'value3'], @cache.read('collection_key') 
      end
      
    end

    context "writing" do
      setup do
        @cache.write('key', 'value')
      end
      
      should "store the object locally" do
        assert_equal 'value', @cache.local['key']
      end
      
      should "persist the object" do
        @cache.clear_local
        assert_equal 'value', @cache.read('key')
      end
      
      should "respect max collection size" do
        original_max = Kasket::CONFIGURATION[:max_collection_size]
        Kasket::CONFIGURATION[:max_collection_size] = 2
        
        @cache.write('key', [ 'a', 'b'])
        assert_equal 2, @cache.read('key').size
        
        @cache.write('key2', ['a', 'b', 'c'])
        assert_equal nil, @cache.read('key2')

        Kasket::CONFIGURATION[:max_collection_size] = original_max
      end
      
    end

    should "delete" do
      @cache.write('key', 'value')
      @cache.delete('key')
      
      assert_equal nil, @cache.local['key']
      assert_equal nil, @cache.read('key')
    end
 
    def delete_matched_local(matcher)
      @local_cache.delete_if { |k,v| k =~ matcher }
    end
 
    should "delete matched local" do
      @cache.write('key1', 'value1')
      @cache.write('key2', 'value2')
      @cache.delete_matched_local(/2/)
      
      assert_equal nil, @cache.local['key2']
      assert_equal 'value1', @cache.local['key1']
      assert_equal 'value2', @cache.read('key2')
    end
    
    should "delete local" do
      @cache.write('key1', 'value1')
      @cache.write('key2', 'value2')
      @cache.delete_local('key1', 'key2')
      
      assert_equal nil, @cache.local['key1']
      assert_equal nil, @cache.local['key2']
      assert_equal 'value1', @cache.read('key1')
      assert_equal 'value2', @cache.read('key2')
    end
    
    should "clear local" do
      @cache.write('key1', 'value1')
      @cache.clear_local
      
      assert @cache.local.blank?
    end

  end
end


