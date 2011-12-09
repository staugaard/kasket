require 'arel'

module Kasket
  class Visitor < Arel::Visitors::Visitor
    def initialize(model_class, binds)
      @model_class = model_class
      @binds       = binds.dup
    end

    def accept(object)
      self.last_column = nil
      super
    end

    def last_column=(col)
      Thread.current[:arel_visitors_to_sql_last_column] = col
    end

    def last_column
      Thread.current[:arel_visitors_to_sql_last_column]
    end

    def column_for(name)
      @model_class.columns_hash[name.to_s]
    end

    def visit_Arel_Nodes_SelectStatement(o)
      return :unsupported if o.with
      return :unsupported if o.offset
      return :unsupported if o.lock
      return :unsupported if o.orders.any?
      return :unsupported if o.cores.size != 1

      query = visit_Arel_Nodes_SelectCore(o.cores[0])
      return query if query == :unsupported

      query = query.inject({}) do |memo, item|
        memo.merge(item)
      end

      query.merge!(visit(o.limit)) if o.limit
      query
    end

    def visit_Arel_Nodes_SelectCore(o)
      return :unsupported if o.groups.any?
      return :unsupported if o.having
      return :unsupported if o.set_quantifier
      return :unsupported if !o.source || o.source.empty?
      return :unsupported if o.projections.size != 1

      select = o.projections[0]
      select = select.name if select.respond_to?(:name)
      return :unsupported if select != '*'

      parts = [visit(o.source)]

      parts += o.wheres.map {|where| visit(where) }

      parts.include?(:unsupported) ? :unsupported : parts
    end

    def visit_Arel_Nodes_Limit(o)
      {:limit => o.value.to_i}
    end

    def visit_Arel_Nodes_JoinSource(o)
      return :unsupported if !o.left || o.right.any?
      return :unsupported if !o.left.is_a?(Arel::Table)
      visit(o.left)
    end

    def visit_Arel_Table(o)
      {:from => o.name}
    end

    def visit_Arel_Nodes_And(o)
      attributes = o.children.map { |child| visit(child) }
      return :unsupported if attributes.include?(:unsupported)
      attributes.sort! { |pair1, pair2| pair1[0].to_s <=> pair2[0].to_s }
      { :attributes => attributes }
    end

    def visit_Arel_Nodes_In(o)
      left = visit(o.left)
      return :unsupported if left != :id

      [left, visit(o.right)]
    end

    def visit_Arel_Nodes_Equality(o)
      right = o.right
      [visit(o.left), right ? visit(right) : nil]
    end

    def visit_Arel_Attributes_Attribute(o)
      self.last_column = column_for(o.name)
      o.name.to_sym
    end

    def literal(o)
      if o == '?'
        column, value = @binds.shift
        value.to_s
      else
        o.to_s
      end
    end

    def visit_Array(o)
      o.map {|value| quoted(value) }
    end

    #TODO: We are actually not using this?
    def quoted(o)
      @model_class.connection.quote(o, self.last_column)
    end

    alias :visit_String                :literal
    alias :visit_Fixnum                :literal
    alias :visit_TrueClass             :literal
    alias :visit_FalseClass            :literal
    alias :visit_Arel_Nodes_SqlLiteral :literal

    def method_missing(name, *args, &block)
      return :unsupported if name.to_s.start_with?('visit_')
      super
    end

    def respond_to?(name, include_private = false)
      return super || name.to_s.start_with?('visit_')
    end

  end
end