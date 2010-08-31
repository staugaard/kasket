require File.dirname(__FILE__) + '/helper'

class ReadMixinTest < ActiveSupport::TestCase

  context "find by sql with kasket" do
    setup do
      @database_results = [ { 'id' => 1, 'title' => 'Hello' }, { 'id' => 2, 'title' => 'World' } ]
      @records = @database_results.map { |r| Post.send(:instantiate, r) }
      Post.stubs(:find_by_sql_without_kasket).returns(@records)
    end

    should "handle unsupported sql" do
      Kasket.cache.expects(:read).never
      Kasket.cache.expects(:write).never
      assert_equal @records, Post.find_by_sql_with_kasket('select unsupported sql statement')
    end

    should "read results" do
      Kasket.cache.write("kasket-#{Kasket::Version::STRING}/posts/version=3558/id=1", @database_results.first)
      assert_equal [ @records.first ], Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)')
    end

    should "store results in kasket" do
      Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)')

      assert_equal @database_results.first, Kasket.cache.read("kasket-#{Kasket::Version::STRING}/posts/version=3558/id=1")
    end

    context "modifying results" do
      setup do
        Kasket.cache.write("kasket-#{Kasket::Version::STRING}/posts/version=3558/id=1", @database_results.first)
        @record = Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)').first
        @record.instance_variable_get(:@attributes)['id'] = 3
      end

      should "not impact other queries" do
        same_record = Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)').first

        assert_not_equal @record, same_record
      end

    end

  end

end
