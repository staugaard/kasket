require File.expand_path("helper", File.dirname(__FILE__))

class ReloadTest < ActiveSupport::TestCase
  context "Reloading a model" do
    setup do
      @post = Post.first
      assert @post
      assert @post.title
    end

    should "clear local cache" do
      Kasket.expects(:clear_local)
      @post.reload
    end
  end

end
