require File.expand_path("helper", File.dirname(__FILE__))

class ReadMixinTest < ActiveSupport::TestCase
  context "find by sql with kasket" do
    setup do
      @post_database_result = { 'id' => 1, 'title' => 'Hello' }
      @post_records = [Post.send(:instantiate, @post_database_result)]
      Post.stubs(:find_by_sql_without_kasket).returns(@post_records)

      @comment_database_result = [{ 'id' => 1, 'body' => 'Hello' }, { 'id' => 2, 'body' => 'World' }]
      @comment_records = @comment_database_result.map {|r| Comment.send(:instantiate, r)}
      Comment.stubs(:find_by_sql_without_kasket).returns(@comment_records)
    end

    should "handle unsupported sql" do
      Kasket.cache.expects(:read).never
      Kasket.cache.expects(:write).never
      assert_equal @post_records, Post.find_by_sql_with_kasket('select unsupported sql statement')
    end

    should "read results" do
      Kasket.cache.write("#{Post.kasket_key_prefix}id=1", @post_database_result)
      assert_equal @post_records, Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)')
    end

    should "support sql with ?" do
      Kasket.cache.write("#{Post.kasket_key_prefix}id=1", @post_database_result)
      assert_equal @post_records, Post.find_by_sql(['SELECT * FROM `posts` WHERE (id = ?)', 1])
    end

    should "store results in kasket" do
      Post.find_by_sql('SELECT * FROM `posts` WHERE (id = 1)')

      assert_equal @post_database_result, Kasket.cache.read("#{Post.kasket_key_prefix}id=1")
    end

    should "store multiple records in cache" do
      Comment.find_by_sql('SELECT * FROM `comments` WHERE (post_id = 1)')
      stored_value = Kasket.cache.read("#{Comment.kasket_key_prefix}post_id=1")
      assert_equal(["#{Comment.kasket_key_prefix}id=1", "#{Comment.kasket_key_prefix}id=2"], stored_value)
      assert_equal(@comment_database_result, stored_value.map {|key| Kasket.cache.read(key)})

      Comment.expects(:find_by_sql_without_kasket).never
      records = Comment.find_by_sql('SELECT * FROM `comments` WHERE (post_id = 1)')
      assert_equal(@comment_records, records.sort {|c1, c2| c1.id <=> c2.id})
    end

    context "modifying results" do
      setup do
        Kasket.cache.write("#{Post.kasket_key_prefix}id=1", {'id' => 1, 'title' => "asd"})
        @sql = 'SELECT * FROM `posts` WHERE (id = 1)'
        @record = Post.find_by_sql(@sql).first
        assert_equal "asd", @record.title # read from cache ?
        @record.instance_variable_get(:@attributes)['id'] = 3
      end

      should "not impact other queries" do
        same_record = Post.find_by_sql(@sql).first

        assert_not_equal @record, same_record
      end

    end

  end

end
