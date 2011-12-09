require File.expand_path("helper", File.dirname(__FILE__))
require "digest/md5"

class ConfigurationMixinTest < ActiveSupport::TestCase
  
  context "Generating cache keys" do
    
    should "not choke on empty numeric attributes" do      
      expected_cache_key = "kasket-#{Kasket::Version::PROTOCOL}/posts/version=4517/blog_id=NULL"
      query_attributes   = [ [:blog_id, ''] ]
      
      assert_equal expected_cache_key, Post.kasket_key_for(query_attributes)
    end

    should "not generate keys longer that 255" do
      very_large_number = (1..999).to_a.join
      query_attributes  = [ [:blog_id, very_large_number] ]
      
      assert(Post.kasket_key_for(query_attributes).size < 255)
    end

    should "not generate keys with spaces" do
      query_attributes = [ [:title, 'this key has speces'] ]
      
      assert(!(Post.kasket_key_for(query_attributes) =~ /\s/))
    end
  end
  
end