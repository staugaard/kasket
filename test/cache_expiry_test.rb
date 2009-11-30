require File.dirname(__FILE__) + '/helper'

class CacheExpiryTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_cache_back
  Post.has_cache_back_on :title
  Post.has_cache_back_on :blog_id

  context "a cached object" do
    setup do
      post = Post.first
      @post = Post.find(post.id)
      assert(Rails.cache.read(@post.cache_back_key))
    end

    should "be removed from cache when deleted" do
      @post.destroy
      assert_nil(Rails.cache.read(@post.cache_back_key))
    end

    should "clear all indices for instance when deleted" do
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "id=#{@post.id}")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "id=#{@post.id}/first")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "title=#{@post.title}")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "title=#{@post.title}/first")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "blog_id=#{@post.blog_id}")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "blog_id=#{@post.blog_id}/first")
      CacheBack.cache.expects(:delete).never

      @post.destroy
    end

    should "be removed from cache when updated" do
      @post.title = "new title"
      @post.save
      assert_nil(Rails.cache.read(@post.cache_back_key))
    end

    should "clear all indices for instance when updated" do
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "id=#{@post.id}")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "id=#{@post.id}/first")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "title=#{@post.title}")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "title=#{@post.title}/first")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "title=new title")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "title=new title/first")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "blog_id=#{@post.blog_id}")
      CacheBack.cache.expects(:delete).with(Post.cache_back_key_prefix + "blog_id=#{@post.blog_id}/first")
      CacheBack.cache.expects(:delete).never

      @post.title = "new title"
      @post.save
    end
  end
end
