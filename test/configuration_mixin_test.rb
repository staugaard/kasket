require File.dirname(__FILE__) + '/helper'

class ConfigurationMixinTest < ActiveSupport::TestCase
  
  context "Generating cache keys" do
    
    should "not choke on empty numeric attributes" do      
      expected_cache_key = "kasket-#{Kasket::Version::STRING}/posts/version=3558/blog_id=NULL"
      query_attributes   = [ [:blog_id, ''] ]
      
      assert_equal expected_cache_key, Post.kasket_key_for(query_attributes)
    end
    
  end
  
end