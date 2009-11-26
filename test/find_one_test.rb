require 'helper'

class FindOneBack < ActiveSupport::TestCase
  fixtures :blogs, :posts
  Post.has_cache_back

  should "cache find(id) calls" do
    post = Post.first
    Post.find(post.id)
    Post.connection.expects(:select_all).never
    Post.find(post.id)
  end
end
