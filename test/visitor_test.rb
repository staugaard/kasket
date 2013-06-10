require File.expand_path("helper", File.dirname(__FILE__))

class VisitorTest < ActiveSupport::TestCase
  if arel?
    context Kasket::Visitor do
      should "build select id" do
        expected = {
          :attributes=>[[:id, "1"]],
          :from=>"posts",
          :index=>[:id],
          :key=>"#{Post.kasket_key_prefix}id=1"
        }
        assert_equal expected, Post.where(:id => 1).to_kasket_query
      end
    end
  end
end
