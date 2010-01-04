require File.dirname(__FILE__) + '/helper'

class FindOneTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  should "cache find(id) calls" do
    post = Post.first
    Rails.cache.write(post.kasket_key, nil)
    assert_equal(post, Post.find(post.id))
    assert(Rails.cache.read(post.kasket_key))
    Post.connection.expects(:select_all).never
    assert_equal(post, Post.find(post.id))
  end

  should "only cache on indexed attributes" do
    Rails.cache.expects(:read).twice
    Post.find_by_id(1)
    Post.find_by_id(1, :conditions => {:blog_id => 2})

    Rails.cache.expects(:read).never
    Post.first :conditions => {:blog_id => 2}
  end

  should "not use cache when using the :select option" do
    post = Post.first
    assert_nil(Rails.cache.read(post.kasket_key))

    Post.find(post.id, :select => 'title')
    assert_nil(Rails.cache.read(post.kasket_key))

    Post.find(post.id)
    assert(Rails.cache.read(post.kasket_key))

    Rails.cache.expects(:read)
    Post.find(post.id, :select => nil)

    Rails.cache.expects(:read).never
    Post.find(post.id, :select => 'title')
  end

  should "respect scope" do
    post = Post.find(Post.first.id)
    other_blog = Blog.first(:conditions => "id != #{post.blog_id}")

    assert(Rails.cache.read(post.kasket_key))

    assert_raise(ActiveRecord::RecordNotFound) do
      other_blog.posts.find(post.id)
    end
  end
end
