require File.expand_path("helper", File.dirname(__FILE__))

class ReloadTest < ActiveSupport::TestCase
  context "Loading a polymorphic belongs_to" do
    should "not clear cache when loading nil" do
      @post = Post.first
      @post.poly = nil
      @post.save!
      Kasket.expects(:clear_local).never
      assert_nil @post.poly
    end

    context "that is uncached" do
      setup do
        @post = Post.first
        @post.poly = Blog.first
        @post.save!
        assert @post.poly
      end

      should "not clear local when it is unloaded" do
        Kasket.expects(:clear_local).never
        assert Post.first.poly
      end

      should "not clear local when it is loaded" do
        Kasket.expects(:clear_local).never
        assert @post.poly.reload
      end
    end

    context "that is cached" do
      setup do
        @post = Post.first
        @post.poly = Comment.first
        @post.save!
        assert @post.poly
      end

      should "clear local when it is loaded" do
        Kasket.expects(:clear_local)
        @post.poly.reload
      end
    end
  end

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

    should "reload via true" do
      @comment = Comment.first
      assert_equal "few_comments", @comment.post.title

      Post.update_all("title = 'yyy'", :id => @comment.post_id)

      assert_equal "few_comments", @comment.post.title
      @comment.post(true) # it does not blow up
      #assert_equal "yyy", @comment.post(true).title # TODO broken in all rails versions...
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
