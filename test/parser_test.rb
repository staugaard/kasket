require 'helper'
require 'kasket/query/parser'

class ParserTest < ActiveSupport::TestCase

  context "Parsing" do
    setup do
      @parser = Kasket::Parser.new(Post) 
    end

    should "extract conditions" do
      assert_equal [[:color, "red"], [:size, "big"]], @parser.attribute_value_pairs('SELECT * FROM `posts` WHERE (`posts`.`color` = red AND `posts`.`size` = big)')
    end
    
    should "only support queries against its model's table" do
      assert !@parser.support?('SELECT * FROM `apples` WHERE (`users`.`id` = 2) ')
    end
    
    should "support cachable queries" do
      assert @parser.support?('SELECT * FROM `posts` WHERE (`posts`.`id` = 2) ')
      assert @parser.support?('SELECT * FROM `posts` WHERE (`posts`.`id` = 2) LIMIT 1')
      assert @parser.support?('SELECT * FROM `posts` WHERE (`posts`.`id` IN (1,2,3,4))')
    end
    
    should "support vaguely formatted queries" do
      assert @parser.support?('SELECT * FROM "posts" WHERE (color = red AND size = big)')
    end
    
    context "extract options" do
      
      should "provide the limit" do
        sql = 'SELECT * FROM `posts` WHERE (`users`.`id` = 2)'
        assert_equal nil, @parser.extract_options(sql)[:limit]
        
        sql << ' LIMIT 1'
        assert_equal 1, @parser.extract_options(sql)[:limit]
      end
      
    end
  
    context "unsupported queries" do
      
      should "include advanced limits" do
        assert !@parser.support?('SELECT * FROM `posts` WHERE (color = red AND size = big) LIMIT 2')
      end
      
      should "include joins" do
        assert !@parser.support?('SELECT * FROM `posts`, `trees` JOIN ON apple.tree_id = tree.id WHERE (color = red)')
      end
      
      should "include specific selects" do
        assert !@parser.support?('SELECT id FROM `posts` WHERE (color = red)')
      end
      
      should "include offset" do
        assert !@parser.support?('SELECT * FROM `posts` WHERE (color = red) LIMIT 1 OFFSET 2')
      end
      
      should "include order" do
        assert !@parser.support?('SELECT * FROM `posts` WHERE (color = red) ORDER DESC')
      end
      
    end
  
  end

end
