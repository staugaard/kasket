module Kasket
  module SelectManagerMixin
    def to_kasket_query(klass, binds = [])
      begin
        query = Kasket::Visitor.new(klass, binds).accept(ast)
      rescue TypeError # unsupported object in ast
        return nil
      end

      return nil if query.nil? || query == :unsupported
      return nil if query[:attributes].blank?

      query[:index] = query[:attributes].map(&:first)

      if query[:limit]
        return nil if query[:limit] > 1
        # return nil if !query[:index].include?(:id)
      end

      if query[:index].size > 1 && query[:attributes].any? { |attribute, value| value.is_a?(Array) }
        return nil
      end

      query[:key] = klass.kasket_key_for(query[:attributes])
      query[:key] << '/first' if query[:limit] == 1 && !query[:index].include?(:id)

      query
    end
  end
end
