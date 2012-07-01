module Kasket
  module RelationMixin
    def to_kasket_query(binds = [])
      if arel.is_a?(Arel::SelectManager)
        arel.to_kasket_query(klass, binds)
      end
    end
  end
end
