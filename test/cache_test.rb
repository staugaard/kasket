require File.dirname(__FILE__) + '/helper'

class CacheTest < ActiveSupport::TestCase

  context "Cache" do
    setup do
      @cache = Kasket::Cache.new      
    end
    
    should "have local caching disabled by default" do
      assert_equal false, @cache.enable_local?
    end
        
  end

  [ true, false ].each do |enable_local|
    context "Cache with local caching set to #{enable_local} " do
      setup do
        @cache = Kasket::Cache.new
        @cache.enable_local = enable_local
        @enable_local = enable_local
      end
      
      should "provide enabled status" do
        assert_equal @enable_local, @cache.enable_local?
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
    
        should "not impact original object" do
          record = { 'id' => 1, 'color' => 'red' }
          @cache.write('key', record)
          record['id'] = 2
    
          assert_not_equal record, @cache.read('key')
        end
    
      end
    
      context "writing" do
        setup do
          @cache.write('key', 'value')
        end
      
        if enable_local
          should "store the object locally" do
            assert_equal 'value', @cache.local['key']
          end
        else
          should "not store the object locally" do
            assert_equal nil, @cache.local['key']
          end
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
        
        should "delete" do
          @cache.write('key', 'value')
          @cache.delete('key')

          assert_equal nil, @cache.local['key']
          assert_equal nil, @cache.read('key')
        end
    
      end
    
      should "delete matched local" do
        @cache.write('key1', 'value1')
        @cache.write('key2', 'value2')
        @cache.delete_matched_local(/2/)
    
        assert_equal nil, @cache.local['key2']
        assert_equal 'value2', @cache.read('key2')
      end
      
      if enable_local
        should "not delete unmatched local keys" do
          @cache.write('key1', 'value1')
          @cache.write('key2', 'value2')
          @cache.delete_matched_local(/2/)
          
          assert_equal 'value1', @cache.local['key1']
        end
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
end
