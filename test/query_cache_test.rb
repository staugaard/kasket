require 'helper'

class QueryCacheTest < ActiveSupport::TestCase
  fixtures :posts
  Post.has_kasket

  should "write to query cache" do
    post = Post.first
    Post.cache do
      Post.find(post.id)
    end
    assert_equal [ post.attributes_before_type_cast ], Rails.cache.read(post.kasket_key), Rails.cache.inspect
  end

end
