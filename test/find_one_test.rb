require File.dirname(__FILE__) + '/helper'

class FindOneTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_kasket

  should "cache find(id) calls" do
    post = Post.first
    
    Post.cache do
      assert_equal nil, Rails.cache.read(post.kasket_key)
      assert_equal(post, Post.find(post.id))
      assert(Rails.cache.read(post.kasket_key))
      Post.connection.expects(:execute).never
      assert_equal(post, Post.find(post.id))
    end
  end

  should "not use persistant cache when using the :select option" do
    Post.cache do
    
     post = Post.first
     assert_nil(Rails.cache.read(post.kasket_key))
    
     Post.find(post.id, :select => 'title')
     assert_nil(Rails.cache.read(post.kasket_key))
    
     Post.find(post.id)
     assert(Rails.cache.read(post.kasket_key))
    
     Kasket.cache.clear_local
     Rails.cache.expects(:read)
     Post.find(post.id, :select => nil)
    
     Rails.cache.expects(:read).never
     Post.find(post.id, :select => 'title')
    end
  end

  should "respect scope" do
    Post.cache do
      post = Post.find(Post.first.id)
      other_blog = Blog.first(:conditions => "id != #{post.blog_id}")
      
      assert(Rails.cache.read(post.kasket_key))
      
      assert_raise(ActiveRecord::RecordNotFound) do
        other_blog.posts.find(post.id)
      end
    end
  end
end
