require File.dirname(__FILE__) + '/helper'

class SerializationTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_cache_back

  should "store a CachedModel" do
    post = Post.first
    post.store_in_cache_back
    assert_instance_of(CacheBack::Cache::CachedModel, Rails.cache.read(post.cache_back_key))
  end

  should "bring convert CachedModel to model instances" do
    post = Post.first
    post.store_in_cache_back

    post = CacheBack.cache.read(post.cache_back_key)
    assert_instance_of(Post, post)
  end
end
