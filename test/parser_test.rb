require File.expand_path("helper", File.dirname(__FILE__))
require 'kasket/query_parser'

class ParserTest < ActiveSupport::TestCase
  def parse(options)
    scope = Post
    if arel?
      options.each do |k,v|
        scope = case k
        when :conditions then scope.where(v)
        else
          scope.send(k, v)
        end
      end
      scope.to_kasket_query
    elsif ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
      @parser.parse(scope.scoped(options).to_sql)
    else
      sql = scope.send(:construct_finder_sql, options)
      @parser.parse(sql)
    end
  end

  context "Parsing" do
    setup do
      @parser = Kasket::QueryParser.new(Post)
    end

    should "not support conditions with number as column (e.g. 0 = 1)" do
      assert !parse(:conditions => "0 = 1")
    end

    should "not support conditions with number as column and parans (e.g. 0 = 1)" do
      assert !parse(:conditions => "(0 = 1)")
    end

    should "not support :order" do
      assert !parse(:conditions => "id = 1", :order => "xxx")
    end

    should 'not support IN queries in combination with other conditions' do
      assert !parse(:conditions => {:id => [1,2,3], :is_active => true})
    end

    should "extract conditions" do
      kasket_query = parse(:conditions => {:title => 'red', :blog_id => 1})
      assert_equal [[:blog_id, "1"], [:title, "red"]], kasket_query[:attributes]
    end

    should "extract conditions with parans that do not surround" do
      kasket_query = parse(:conditions => "(title = 'red') AND (blog_id = 1)")
      if ActiveRecord::VERSION::STRING > "3.1.0"
        assert !kasket_query
      else
        assert_equal [[:blog_id, "1"], [:title, "red"]], kasket_query[:attributes]
      end
    end

    should "extract required index" do
      assert_equal [:blog_id, :title], parse(:conditions => {:title => 'red', :blog_id => 1})[:index]
    end

    should "only support queries against its model's table" do
      assert !parse(:conditions => {'blogs.id' => 2}, :from => 'apples')
    end

    should "support cachable queries" do
      assert parse(:conditions => {:id => 1})
      assert parse(:conditions => {:id => 1}, :limit => 1)
    end

    should "support IN queries on id" do
      assert_equal [[:id, ['1', '2', '3']]], parse(:conditions => {:id => [1,2,3]})[:attributes]
    end

    should "not support IN queries on other attributes" do
      assert !parse(:conditions => {:hest => [1,2,3]})
    end

    should "support vaguely formatted queries" do
      assert @parser.parse('SELECT * FROM "posts" WHERE (title = red AND blog_id = big)')
    end

    context "extract options" do
      should "provide the limit" do
        assert_equal nil, parse(:conditions => {:id => 2})[:limit]
        assert_equal 1, parse(:conditions => {:id => 2}, :limit => 1)[:limit]
      end
    end

    context "unsupported queries" do
      should "include advanced limits" do
        assert !parse(:conditions => {:title => 'red', :blog_id => 1}, :limit => 2)
      end

      should "include joins" do
        assert !parse(:conditions => {:title => 'test', 'apple.tree_id' => 'posts.id'}, :from => ['posts', 'apple'])
        assert !parse(:conditions => {:title => 'test'}, :joins => :comments)
      end

      should "include specific selects" do
        assert !parse(:conditions => {:title => 'red'}, :select => :id)
      end

      should "include offset" do
        assert !parse(:conditions => {:title => 'red'}, :limit => 1, :offset => 2)
      end

      should "include order" do
        assert !parse(:conditions => {:title => 'red'}, :order => :title)
      end

      should "include the OR operator" do
        assert !parse(:conditions => "title = 'red' OR blog_id = 1")
      end
    end

    context "key generation" do
      should "include the table name and version" do
        kasket_query = parse(:conditions => {:id => 1})
        assert_match(/^kasket-#{Kasket::Version::PROTOCOL}\/R#{ActiveRecord::VERSION::MAJOR}#{ActiveRecord::VERSION::MINOR}\/posts\/version=#{POST_VERSION}\//, kasket_query[:key])
      end

      should "include all indexed attributes" do
        kasket_query = parse(:conditions => {:id => 1})
        assert_match(/id=1$/, kasket_query[:key])

        kasket_query = parse(:conditions => {:id => 1, :blog_id => 2})
        assert_match(/blog_id=2\/id=1$/, kasket_query[:key])

        kasket_query = parse(:conditions => {:id => 1, :title => 'title'})
        assert_match(/id=1\/title='title'$/, kasket_query[:key])
      end

      should "generate multiple keys on IN queries" do
        keys = parse(:conditions => {:id => [1,2]})[:key]
        assert_instance_of(Array, keys)
        assert_match(/id=1$/, keys[0])
        assert_match(/id=2$/, keys[1])
      end

      context "when limit 1" do
        should "add /first to the key if the index does not include id" do
          assert_match(/title='a'\/first$/, parse(:conditions => {:title => 'a'}, :limit => 1)[:key])
        end

        should "not add /first to the key when the index includes id" do
          assert_match(/id=1$/, parse(:conditions => {:id => 1}, :limit => 1)[:key])
        end
      end
    end
  end
end
