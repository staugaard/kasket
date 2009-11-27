require File.dirname(__FILE__) + '/helper'

class FindOneTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_cache_back

  should "cache find(id) calls" do
    post = Post.first
    assert_nil(Rails.cache.read(post.cache_back_key))
    assert_equal(post, Post.find(post.id))
    assert(Rails.cache.read(post.cache_back_key))
    Post.connection.expects(:select_all).never
    assert_equal(post, Post.find(post.id))
  end

  should "not use cache when using the :select option" do
    post = Post.first
    assert_nil(Rails.cache.read(post.cache_back_key))

    Post.find(post.id, :select => 'title')
    assert_nil(Rails.cache.read(post.cache_back_key))

    Post.find(post.id)
    assert(Rails.cache.read(post.cache_back_key))

    CacheBack.cache.expects(:read)
    Post.find(post.id, :select => nil)

    CacheBack.cache.expects(:read).never
    Post.find(post.id, :select => 'title')
  end

  should "respect scope" do
    post = Post.find(Post.first.id)
    other_blog = Blog.first(:conditions => "id != #{post.blog_id}")

    assert(Rails.cache.read(post.cache_back_key))

    assert_raise(ActiveRecord::RecordNotFound) do
      other_blog.posts.find(post.id)
    end
  end
end
