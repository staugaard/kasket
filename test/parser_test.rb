require 'helper'
require 'kasket/query/parser'

class ParserTest < ActiveSupport::TestCase

  context "Parsing" do
    setup do
      @parser = Kasket::Parser.new(ActiveRecord::Base) 
    end

    should "extract conditions" do
      assert_equal [[:color, "red"], [:size, "big"]], @parser.attribute_value_pairs('SELECT * FROM `apples` WHERE (`color` = red and `size` = big)')
     # assert_equal [ [:id, [1,2,3,4]] ], @parser.attribute_value_pairs('SELECT * FROM `apples` WHERE (`id` IN (1,2,3,4))')
    end
    
    should "support cachable queries" do
      assert @parser.support?('SELECT * FROM `users` WHERE (`users`.`id` = 2) ')
      assert @parser.support?('SELECT * FROM `users` WHERE (`users`.`id` = 2) LIMIT 1')
    end
    
    should "support differently formatted queries" do
      assert @parser.support?('SELECT * FROM "apples" WHERE (color = red AND size = big)')
     # assert @parser.support?('SELECT * FROM apples WHERE color = red AND size = big LIMIT 1')
     # assert @parser.support?('SELECT * FROM apples WHERE id IN(1,2,3,4)')
    end
    
    context "extract options" do
      
      should "provide the limit" do
        sql = 'SELECT * FROM `users` WHERE (`users`.`id` = 2)'
        assert_equal nil, @parser.extract_options(sql)[:limit]
        
        sql << ' LIMIT 1'
        assert_equal '1', @parser.extract_options(sql)[:limit]
      end
      
    end
  
    context "unsupported queries" do
      
      should "include advanced limits" do
        assert !@parser.support?('SELECT * FROM `apples` WHERE (color = red AND size = big) LIMIT 2')
      end
      
      should "include joins" do
        assert !@parser.support?('SELECT * FROM `apples`, `trees` JOIN ON apple.tree_id = tree.id WHERE (color = red)')
      end
      
      should "include specific selects" do
        assert !@parser.support?('SELECT id FROM `apples` WHERE (color = red)')
      end
      
      should "include offset" do
        assert !@parser.support?('SELECT * FROM `apples` WHERE (color = red) LIMIT 1 OFFSET 2')
      end
      
      should "include order" do
        assert !@parser.support?('SELECT * FROM `apples` WHERE (color = red) ORDER DESC')
      end
      
    end
  
  end

end
