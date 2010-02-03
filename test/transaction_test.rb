require File.dirname(__FILE__) + '/helper'

class TransactionTest < ActiveSupport::TestCase
  context "Transactions" do 
    should "have kasket disabled" do
      assert_equal true, Post.use_kasket?
      Post.transaction do
        assert_equal false, Post.use_kasket?
      end
      assert_equal true, Post.use_kasket?
    end
  end

  context "Nested transactions" do
    setup { Comment.has_kasket } 
    should "disable kasket" do 
      Post.transaction do
        assert_equal true,  Comment.use_kasket?
        assert_equal false, Post.use_kasket?
        Comment.transaction do
          assert_equal false, Post.use_kasket?
          assert_equal false, Comment.use_kasket?
        end
      end
    end
  end
end
