# -*- encoding: utf-8 -*-
require 'active_support'
require "digest/md5"

module Kasket

  module ConfigurationMixin

    def without_kasket(&block)
      old_value = Thread.current['kasket_disabled'] || false
      Thread.current['kasket_disabled'] = true
      yield
    ensure
      Thread.current['kasket_disabled'] = old_value
    end

    def use_kasket?
      !Thread.current['kasket_disabled']
    end

    def kasket_parser
      @kasket_parser ||= QueryParser.new(self)
    end

    def kasket_key_prefix
      @kasket_key_prefix ||= "kasket-#{Kasket::Version::PROTOCOL}/#{kasket_activerecord_version}/#{table_name}/version=#{column_names.join.sum}/"
    end

    def kasket_activerecord_version
      "R#{ActiveRecord::VERSION::MAJOR}#{ActiveRecord::VERSION::MINOR}"
    end

    def kasket_key_for(attribute_value_pairs)
      if attribute_value_pairs.size == 1 && attribute_value_pairs[0][0] == :id && attribute_value_pairs[0][1].is_a?(Array)
        attribute_value_pairs[0][1].map {|id| kasket_key_for_id(id)}
      else
        key = attribute_value_pairs.map do |attribute, value|
          column = columns_hash[attribute.to_s]
          value = nil if value.blank?
          attribute.to_s + '=' + connection.quote(column.type_cast(value), column).downcase
        end.join('/')

        if key.size > (250 - kasket_key_prefix.size) || key =~ /\s/
          key = Digest::MD5.hexdigest(key)
        end

        kasket_key_prefix + key
      end
    end

    def kasket_key_for_id(id)
      kasket_key_for([['id', id]])
    end

    def kasket_indices
      result = @kasket_indices || []
      result += superclass.kasket_indices unless self == ActiveRecord::Base
      result.uniq
    end

    def has_kasket_index_on?(sorted_attributes)
      kasket_indices.include?(sorted_attributes)
    end

    def has_kasket(options = {})
      has_kasket_on :id
    end

    def has_kasket_on(*args)
      attributes = args.sort! { |x, y| x.to_s <=> y.to_s }
      if attributes != [:id] && !kasket_indices.include?([:id])
        has_kasket_on(:id)
      end

      @kasket_indices ||= []
      @kasket_indices << attributes unless @kasket_indices.include?(attributes)

      include WriteMixin unless include?(WriteMixin)
      extend DirtyMixin unless respond_to?(:kasket_dirty_methods)
      extend ReadMixin unless methods.map(&:to_sym).include?(:find_by_sql_with_kasket)
    end
  end
end
