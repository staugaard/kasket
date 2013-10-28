require File.expand_path("helper", File.dirname(__FILE__))

module Nori
  class StringWithAttributes < String
  end

  class AnotherString < String
  end
end

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

      should "build from Nori::StringWithAttributes" do
        expected = {
          :attributes=>[[:id, "1"]],
          :from=>"posts",
          :index=>[:id],
          :key=>"#{Post.kasket_key_prefix}id=1"
        }
        assert_equal expected, Post.where(:id => Nori::StringWithAttributes.new("1")).to_kasket_query
      end

      should "notify on missing attribute" do
        log = StringIO.new
        ActiveRecord::Base.logger = Logger.new(log)
        Post.where(:id => Nori::AnotherString.new("1")).to_kasket_query
        assert_includes log.string, "Kasket: Cannot visit unsupported class via visit_Nori_AnotherString and"
      end
    end
  end
end
