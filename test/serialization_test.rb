require File.dirname(__FILE__) + '/helper'

class SerializationTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_kasket

  should "store a CachedModel" do
    post = Post.first
    post.store_in_kasket
    assert_instance_of(Kasket::Cache::CachedModel, Rails.cache.read(post.kasket_key))
  end

  should "bring convert CachedModel to model instances" do
    post = Post.first
    post.store_in_kasket

    post = Kasket.cache.read(post.kasket_key)
    assert_instance_of(Post, post)
  end
end
