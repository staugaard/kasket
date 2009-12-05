require File.dirname(__FILE__) + '/helper'
require 'kasket/query_parser'

class ParserTest < ActiveSupport::TestCase

  context "Parsing" do
    setup do
      @parser = Kasket::QueryParser.new(Post)
    end

    should "extract conditions" do
      assert_equal [[:color, "red"], [:size, "big"]], @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`color` = red AND `posts`.`size` = big)')[:attributes]
    end

    should "extract required index" do
      assert_equal [:color, :size], @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`color` = red AND `posts`.`size` = big)')[:index]
    end

    should "only support queries against its model's table" do
      assert !@parser.parse('SELECT * FROM `apples` WHERE (`users`.`id` = 2) ')
    end

    should "support cachable queries" do
      assert @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` = 2) ')
      assert @parser.parse('SELECT * FROM `posts` WHERE (`posts`.`id` = 2) LIMIT 1')
    end

    should "support vaguely formatted queries" do
      assert @parser.parse('SELECT * FROM "posts" WHERE (color = red AND size = big)')
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
        assert !@parser.parse('SELECT * FROM `posts` WHERE (color = red AND size = big) LIMIT 2')
      end

      should "include joins" do
        assert !@parser.parse('SELECT * FROM `posts`, `trees` JOIN ON apple.tree_id = tree.id WHERE (color = red)')
      end

      should "include specific selects" do
        assert !@parser.parse('SELECT id FROM `posts` WHERE (color = red)')
      end

      should "include offset" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (color = red) LIMIT 1 OFFSET 2')
      end

      should "include order" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (color = red) ORDER DESC')
      end

      should "include the OR operator" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (color = red OR size = big) LIMIT 2')
      end

      should "include the IN operator" do
        assert !@parser.parse('SELECT * FROM `posts` WHERE (id IN (1,2,3))')
      end

    end

    context "key generation" do
      should "include the table name and version" do
        assert_match(/^kasket\/posts\/version=3558\//, @parser.parse('SELECT * FROM `posts` WHERE (id = 1)')[:key])
      end

      should "include all indexed attributes" do
        assert_match(/id=1$/, @parser.parse('SELECT * FROM `posts` WHERE (id = 1)')[:key])
        assert_match(/blog_id=2\/id=1$/, @parser.parse('SELECT * FROM `posts` WHERE (id = 1 AND blog_id = 2)')[:key])
        assert_match(/id=1\/title='world\\'s best title'$/, @parser.parse("SELECT * FROM `posts` WHERE (id = 1 AND title = 'world\\'s best title')")[:key])
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
