require File.expand_path("helper", File.dirname(__FILE__))
require 'kasket/query_parser'

class ParserTest < ActiveSupport::TestCase

  context "Parsing" do
    setup do
      @parser = Kasket::QueryParser.new(Post)
    end

    should 'not support IN queries in combination with other conditions' do
      if ar3?
        kasket_query = Post.where(:id => [1,2,3], :is_active => true).to_kasket_query
      else
        kasket_query = @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` IN (1,2,3) AND `posts`.`is_active` = 1)')
      end
      assert(!kasket_query)
    end

    should "extract conditions" do
      if ar3?
        kasket_query = Post.where(:title => 'red', :blog_id => 1).to_kasket_query
      else
        kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`title` = 'red' AND `posts`.`blog_id` = 1)")
      end
      assert_equal [[:blog_id, "1"], [:title, "red"]], kasket_query[:attributes]
    end

    should "extract required index" do
      if ar3?
        kasket_query = Post.where(:title => 'red', :blog_id => 1).to_kasket_query
      else
        kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`title` = 'red' AND `posts`.`blog_id` = 1)")
      end
      assert_equal [:blog_id, :title], kasket_query[:index]
    end

    should "only support queries against its model's table" do
      if ar3?
        kasket_query = Post.where('users.id' => 2).from('apples').to_kasket_query
      else
        kasket_query = @parser.parse("SELECT * FROM `apples` WHERE (`users`.`id` = 2)")
      end
      assert(!kasket_query)
    end

    should "support cachable queries" do
      if ar3?
        assert Post.where(:id => 1).to_kasket_query
      else
        assert @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`id` = 2)")
      end

      if ar3?
        assert Post.where(:id => 1).limit(1).to_kasket_query
      else
        assert @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`id` = 2) LIMIT 1")
      end
    end

    should "support IN queries on id" do
      if ar3?
        kasket_query = Post.where(:id => [1,2,3]).to_kasket_query
      else
        kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`id` IN (1,2,3))")
      end
      assert(kasket_query)
      assert_equal([[:id, ['1', '2', '3']]], kasket_query[:attributes])
    end

    should "not support IN queries on other attributes" do
      if ar3?
        kasket_query = Post.where(:hest => [1,2,3]).to_kasket_query
      else
        kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`hest` IN (1,2,3))")
      end
      assert(!kasket_query)
    end

    should "support vaguely formatted queries" do
      assert @parser.parse('SELECT * FROM "posts" WHERE (title = red AND blog_id = big)')
    end

    context "extract options" do

      should "provide the limit" do
        if ar3?
          kasket_query = Post.where(:id => 2).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`id` = 2)")
        end
        assert_equal nil, kasket_query[:limit]

        if ar3?
          kasket_query = Post.where(:id => 2).limit(1).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (`posts`.`id` = 2) LIMIT 1")
        end
        assert_equal 1, kasket_query[:limit]
      end

    end

    context "unsupported queries" do

      should "include advanced limits" do
        if ar3?
          kasket_query = Post.where(:title => 'red', :blog_id => 1).limit(2).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (title = 'red' AND blog_id = 1) LIMIT 2")
        end
        assert !kasket_query
      end

      should "include joins" do
        if ar3?
          kasket_query = Post.where(:title => 'test', 'apple.tree_id' => 'posts.id').from(['posts', 'apple']).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts`, `trees` JOIN ON apple.tree_id = tree.id")
        end
        assert !kasket_query

        if ar3?
          kasket_query = Post.where(:title => 'test').joins(:comments).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` JOIN `trees` ON apple.tree_id = tree.id")
        end
        assert !kasket_query
      end

      should "include specific selects" do
        if ar3?
          kasket_query = Post.where(:title => 'red').select(:id).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT id FROM `posts` WHERE (title = 'red')")
        end
        assert !kasket_query
      end

      should "include offset" do
        if ar3?
          kasket_query = Post.where(:title => 'red').limit(1).offset(2).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (title = 'red') LIMIT 1 OFFSET 2")
        end
        assert !kasket_query
      end

      should "include order" do
        if ar3?
          kasket_query = Post.where(:title => 'red').order(:title).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (title = 'red') ORDER DESC")
        end
        assert !kasket_query
      end

      should "include the OR operator" do
        if ar3?
          kasket_query = Post.where("title = 'red' OR blog_id = 1").to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (title = 'red' OR blog_id = 1) LIMIT 2")
        end
        assert !kasket_query
      end
    end

    context "key generation" do
      should "include the table name and version" do
        if ar3?
          kasket_query = Post.where(:id => 1).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (id = 1)")
        end
        assert_match(/^kasket-#{Kasket::Version::STRING}\/posts\/version=3558\//, kasket_query[:key])
      end

      should "include all indexed attributes" do
        if ar3?
          kasket_query = Post.where(:id => 1).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (id = 1)")
        end
        assert_match(/id=1$/, kasket_query[:key])

        if ar3?
          kasket_query = Post.where(:id => 1, :blog_id => 2).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (id = 1 AND blog_id = 2)")
        end
        assert_match(/blog_id=2\/id=1$/, kasket_query[:key])

        if ar3?
          kasket_query = Post.where(:id => 1, :title => 'title').to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (id = 1 AND title = 'title')")
        end
        assert_match(/id=1\/title='title'$/, kasket_query[:key])
      end

      should "generate multiple keys on IN queries" do
        if ar3?
          kasket_query = Post.where(:id => [1,2]).to_kasket_query
        else
          kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (id IN (1,2))")
        end

        keys = kasket_query[:key]
        assert_instance_of(Array, keys)
        assert_match(/id=1$/, keys[0])
        assert_match(/id=2$/, keys[1])
      end

      context "when limit 1" do
        should "add /first to the key if the index does not include id" do
          if ar3?
            kasket_query = Post.where(:title => 'a').limit(1).to_kasket_query
          else
            kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (title = 'a') LIMIT 1")
          end
          assert_match(/title='a'\/first$/, kasket_query[:key])
        end
        should "not add /first to the key when the index includes id" do
          if ar3?
            kasket_query = Post.where(:id => 1).limit(1).to_kasket_query
          else
            kasket_query = @parser.parse("SELECT * FROM `posts` WHERE (id = 1) LIMIT 1")
          end
          assert_match(/id=1$/, kasket_query[:key])
        end
      end
    end
  end

end
