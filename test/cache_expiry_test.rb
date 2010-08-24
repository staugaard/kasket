require File.dirname(__FILE__) + '/helper'

class CacheExpiryTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  context "a cached object" do
    setup do
      post = Post.first
      @post = Post.find(post.id)

      assert(Kasket.cache.read(@post.kasket_key))
    end

    should "be removed from cache when deleted" do
      @post.destroy
      assert_nil(Kasket.cache.read(@post.kasket_key))
    end

    should "clear all indices for instance when deleted" do
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "id=#{@post.id}")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "title='#{@post.title}'")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "title='#{@post.title}'/first")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "blog_id=#{@post.blog_id}/id=#{@post.id}")
      Kasket.cache.expects(:delete).never

      @post.destroy
    end

    should "be removed from cache when updated" do
      @post.title = "new_title"
      @post.save
      assert_nil(Kasket.cache.read(@post.kasket_key))
    end

    should "clear all indices for instance when updated" do
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "id=#{@post.id}")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "title='#{@post.title}'")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "title='#{@post.title}'/first")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "title='new_title'")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "title='new_title'/first")
      Kasket.cache.expects(:delete).with(Post.kasket_key_prefix + "blog_id=#{@post.blog_id}/id=#{@post.id}")
      Kasket.cache.expects(:delete).never

      @post.title = "new_title"
      @post.save
    end

  end
end
