require File.expand_path("helper", File.dirname(__FILE__))

class FindSomeTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  def setup
    @post1 = Post.first
    @post2 = Post.last
    Post.find(@post1.id, @post2.id)
    assert Kasket.cache.read(@post1.kasket_key)
    assert Kasket.cache.read(@post2.kasket_key)
  end

  should "use cache for find(id, id) calls" do
    Post.connection.expects(:select_all).never
    Post.find(@post1.id, @post2.id)
  end

  should "cache when found using find(id, id) calls" do
    Kasket.cache.delete(@post1.kasket_key)
    Kasket.cache.delete(@post2.kasket_key)

    Post.find(@post1.id, @post2.id)

    assert Kasket.cache.read(@post1.kasket_key)
    assert Kasket.cache.read(@post2.kasket_key)
  end

  should "only lookup the records that are not in the cache" do
    Kasket.cache.delete(@post2.kasket_key)

    # has to lookup post2 via db
    Post.expects(:find_by_sql_without_kasket).returns([@post2])
    found_posts = Post.find(@post1.id, @post2.id)
    assert_equal [@post1, @post2].map(&:id).sort, found_posts.map(&:id).sort

    # now all are cached
    Post.expects(:find_by_sql_without_kasket).never
    found_posts = Post.find(@post1.id, @post2.id)
    assert_equal [@post1, @post2].map(&:id).sort, found_posts.map(&:id).sort
  end

  context "unfound" do
    should "ignore unfound when using find_all_by_id" do
      found_posts = Post.find_all_by_id([@post1.id, 1231232])
      assert_equal [@post1.id], found_posts.map(&:id)
    end

    should "not ignore unfound when using find" do
      assert_raise ActiveRecord::RecordNotFound do
        Post.find(@post1.id, 1231232)
      end
    end
  end
end
