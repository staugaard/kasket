require File.expand_path("helper", File.dirname(__FILE__))

class FindOneTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  should "cache find(id) calls" do
    post = Post.first
    Kasket.cache.write(post.kasket_key, nil)
    assert_equal(post, Post.find(post.id))
    assert(Kasket.cache.read(post.kasket_key))
    Post.connection.expects(:select_all).never
    assert_equal(post, Post.find(post.id))
  end

  should "only cache on indexed attributes" do
    Kasket.cache.expects(:read).twice
    Post.find_by_id(1)
    Post.find_by_id(1, :conditions => {:blog_id => 2})

    Kasket.cache.expects(:read).never
    Post.first :conditions => {:blog_id => 2}
  end

  should "not use cache when using the :select option" do
    post = Post.first
    assert_nil(Kasket.cache.read(post.kasket_key))

    Post.find(post.id, :select => 'title')
    assert_nil(Kasket.cache.read(post.kasket_key))

    Post.find(post.id)
    assert(Kasket.cache.read(post.kasket_key))

    Kasket.cache.expects(:read)
    Post.find(post.id, :select => nil)

    Kasket.cache.expects(:read).never
    Post.find(post.id, :select => 'title')
  end

  should "respect scope" do
    post = Post.find(Post.first.id)
    other_blog = Blog.first(:conditions => "id != #{post.blog_id}")

    assert(Kasket.cache.read(post.kasket_key))

    assert_raise(ActiveRecord::RecordNotFound) do
      other_blog.posts.find(post.id)
    end
  end

  should "use same scope when finding on has_many" do
    post = Blog.first.posts.first
    blog = Blog.first
    Rails.cache.clear

    post = blog.posts.find_by_id(post.id)
    key  = post.kasket_key.sub(%r{(/id=#{post.id})}, "/blog_id=#{Blog.first.id}\\1")
    assert(Kasket.cache.read(key))
  end
end
