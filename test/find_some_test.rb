require File.dirname(__FILE__) + '/helper'

class FindSomeTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_kasket
  Post.has_kasket_on :blog_id

  should "cache find(id, id) calls" do
    post1 = Post.first
    post2 = Post.last

    assert_nil(Rails.cache.read(post1.kasket_key))
    assert_nil(Rails.cache.read(post2.kasket_key))

    Post.find(post1.id, post2.id)

    assert(Rails.cache.read(post1.kasket_key))
    assert(Rails.cache.read(post2.kasket_key))

    Post.connection.expects(:select_all).never
    Post.find(post1.id, post2.id)
  end

  should "only lookup the records that are not in the cache" do
    post1 = Post.first
    post2 = Post.last
    assert_equal(post1, Post.find(post1.id))
    assert(Rails.cache.read(post1.kasket_key))
    assert_nil(Rails.cache.read(post2.kasket_key))

    Post.expects(:find_some_without_kasket).with([post2.id], {}).returns([post2])
    found_posts = Post.find(post1.id, post2.id)
    assert_equal([post1, post2].map(&:id).sort, found_posts.map(&:id).sort)

    Post.expects(:find_some_without_kasket).never
    found_posts = Post.find(post1.id, post2.id)
    assert_equal([post1, post2].map(&:id).sort, found_posts.map(&:id).sort)
  end

  should "cache on index other than primary key" do
    blog = blogs(:a_blog)
    posts = Post.find_all_by_blog_id(blog.id)

    Post.expects(:find_every_without_kasket).never

    assert_equal(posts, Post.find_all_by_blog_id(blog.id))
  end
end
