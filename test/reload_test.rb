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

  context "Reloading a belongs_to association" do
    setup do
      @post = Comment.first.post
      assert @post
      assert @post.title
    end

    should "clear local cache" do
      Kasket.expects(:clear_local)
      @post.reload
    end
  end

  context "Reloading a has_one_through association" do
    setup do
      @author = Comment.first.author
      assert @author
      assert @author.name
    end

    should "clear local cache" do
      Kasket.expects(:clear_local)
      @author.reload
    end
  end
end
