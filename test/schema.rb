ActiveRecord::Schema.define(:version => 1) do
  suppress_messages do
    create_table 'comments', :force => true do |t|
      t.text     'body'
      t.integer  'post_id'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'authors', :force => true do |t|
      t.string 'name'
    end

    create_table 'posts', :force => true do |t|
      t.string   'title'
      t.integer  'author_id'
      t.integer  'blog_id'
      t.integer  'poly_id'
      t.string   'poly_type'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    create_table 'blogs', :force => true do |t|
      t.string   'name'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end
  end
end
