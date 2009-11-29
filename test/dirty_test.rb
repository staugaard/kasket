require File.dirname(__FILE__) + '/helper'

class DirtyTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  Post.has_cache_back
  Post.cache_back_dirty_methods :make_dirty!

  should "clear the indices when a dirty method is called" do
    post = Post.first

    pots = Post.find(post.id)
    assert(Rails.cache.read(post.cache_back_key))

    post.make_dirty!

    assert_nil(Rails.cache.read(post.cache_back_key))
  end
end
