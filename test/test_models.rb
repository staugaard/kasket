require 'temping'
include Temping

create_model :comment do
  with_columns do |t|
    t.text     "body"
    t.integer  "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  belongs_to :post
end

create_model :post do
  with_columns do |t|
    t.string   "title"
    t.integer  "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  belongs_to :blog
  has_many :comments

  has_kasket
  has_kasket_on :title
  has_kasket_on :blog_id, :id

  def make_dirty!
    self.updated_at = Time.now
    self.connection.execute("UPDATE posts SET updated_at = '#{updated_at.utc.to_s(:db)}' WHERE id = #{id}")
  end
  kasket_dirty_methods :make_dirty!
end

create_model :blog do
  with_columns do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  has_many :posts
end
