require File.expand_path("helper", File.dirname(__FILE__))
require 'kasket/query_parser'

class ParserTest < ActiveSupport::TestCase

  context "Parsing" do
    setup do
      @parser = Kasket::QueryParser.new(Post)
    end

    should "not support conditions with number as column (e.g. 0 = 1)" do
      kasket_query = @parser.parse('SELECT * FROM `posts` WHERE (0 = 1)')
      assert(!kasket_query)
    end

    should 'not support IN queries in combination with other conditions' do
      parsed_query = @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` IN (1,2,3) AND `posts`.`is_active` = 1)')
      assert(!parsed_query)
    end

    should "extract conditions" do
      assert_equal [[:blog_id, "big"], [:title, "red"]], @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`title` = red AND `posts`.`blog_id` = big)')[:attributes]
    end

    should "extract required index" do
      assert_equal [:blog_id, :title], @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`title` = red AND `posts`.`blog_id` = big)')[:index]
    end

    should "only support queries against its model's table" do
      assert !@parser.parse('SELECT * FROM `apples` WHERE (`users`.`id` = 2) ')
    end

    should "support cachable queries" do
      assert @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` = 2) ')
      assert @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` = 2) LIMIT 1')
    end

    should "support IN queries on id" do
      parsed_query = @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` IN (1,2,3))')
      assert(parsed_query)
      assert_equal([[:id, ['1', '2', '3']]], parsed_query[:attributes])
    end

    should "not support IN queries on other attributes" do
      assert(!@parser.parse('SELECT * FROM `posts` WHERE (`posts`.`hest` IN (1,2,3))'))
    end

    should "support vaguely formatted queries" do
      assert @parser.parse('SELECT * FROM "posts" WHERE (title = red AND blog_id = big)')
    end

    context "extract options" do

      should "provide the limit" do
        sql = 'SELECT * FROM `posts` WHERE (`posts`.`id` = 2)'
        assert_equal nil, @parser.parse(sql)[:limit]

        sql << ' LIMIT 1'
        assert_equal 1, @parser.parse(sql)[:limit]
      end

    end

    context "unsupported queries" do

      should "include advanced limits" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (title = red AND blog_id = big) LIMIT 2')
      end

      should "include joins" do
        assert !@parser.parse('SELECT * FROM `posts`, `trees` JOIN ON apple.tree_id = tree.id WHERE (title = red)')
      end

      should "include specific selects" do
        assert !@parser.parse('SELECT id FROM `posts` WHERE (title = red)')
      end

      should "include offset" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (title = red) LIMIT 1 OFFSET 2')
      end

      should "include order" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (title = red) ORDER DESC')
      end

      should "include the OR operator" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (title = red OR blog_id = big) LIMIT 2')
      end
    end

    context "key generation" do
      should "include the table name and version" do
        assert_match(/^kasket-#{Kasket::Version::STRING}\/posts\/version=3558\//, @parser.parse('SELECT * FROM `posts` WHERE (id = 1)')[:key])
      end

      should "include all indexed attributes" do
        assert_match(/id=1$/, @parser.parse('SELECT * FROM `posts` WHERE (id = 1)')[:key])
        assert_match(/blog_id=2\/id=1$/, @parser.parse('SELECT * FROM `posts` WHERE (id = 1 AND blog_id = 2)')[:key])
        assert_match(/id=1\/title='title'$/, @parser.parse("SELECT * FROM `posts` WHERE (id = 1 AND title = 'title')")[:key])
      end

      should "generate multiple keys on IN queries" do
        keys = @parser.parse('SELECT * FROM `posts` WHERE (id IN (1,2))')[:key]
        assert_instance_of(Array, keys)
        assert_match(/id=1$/, keys[0])
        assert_match(/id=2$/, keys[1])
      end

      context "when limit 1" do
        should "add /first to the key if the index does not include id" do
          assert_match(/title='a'\/first$/, @parser.parse("SELECT * FROM `posts` WHERE (title = 'a') LIMIT 1")[:key])
        end
        should "not add /first to the key when the index includes id" do
          assert_match(/id=1$/, @parser.parse("SELECT * FROM `posts` WHERE (id = 1) LIMIT 1")[:key])
        end
      end
    end
  end

end
