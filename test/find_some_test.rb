require File.dirname(__FILE__) + '/helper'

class FindSomeTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_cache_back

  should "cache find(id, id) calls" do
    post1 = Post.first
    post2 = Post.last

    assert_nil(Rails.cache.read(post1.cache_back_key))
    assert_nil(Rails.cache.read(post2.cache_back_key))

    Post.find(post1.id, post2.id)

    assert(Rails.cache.read(post1.cache_back_key))
    assert(Rails.cache.read(post2.cache_back_key))

    Post.connection.expects(:select_all).never
    Post.find(post1.id, post2.id)
  end

  should "only lookup the records that are not in the cache" do
    post1 = Post.first
    post2 = Post.last
    assert_equal(post1, Post.find(post1.id))
    assert(Rails.cache.read(post1.cache_back_key))
    assert_nil(Rails.cache.read(post2.cache_back_key))

    Post.expects(:find_some_without_cache_back).with([post2.id], {}).returns([post2])
    found_posts = Post.find(post1.id, post2.id)
    assert_equal([post1, post2].map(&:id).sort, found_posts.map(&:id).sort)

    Post.expects(:find_some_without_cache_back).never
    found_posts = Post.find(post1.id, post2.id)
    assert_equal([post1, post2].map(&:id).sort, found_posts.map(&:id).sort)
  end
end
