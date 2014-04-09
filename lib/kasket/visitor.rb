require 'arel'

module Kasket
  class Visitor < Arel::Visitors::Visitor
    def initialize(model_class, binds)
      @model_class = model_class
      @binds       = binds.dup
    end

    def accept(node)
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

    def visit_Arel_Nodes_SelectStatement(node)
      return :unsupported if node.with
      return :unsupported if node.offset
      return :unsupported if node.lock
      return :unsupported if node.orders.any?
      return :unsupported if node.cores.size != 1

      query = visit_Arel_Nodes_SelectCore(node.cores[0])
      return query if query == :unsupported

      query = query.inject({}) do |memo, item|
        memo.merge(item)
      end

      query.merge!(visit(node.limit)) if node.limit
      query
    end

    def visit_Arel_Nodes_SelectCore(node)
      return :unsupported if node.groups.any?
      return :unsupported if node.having
      return :unsupported if node.set_quantifier
      return :unsupported if (!node.source || node.source.empty?)
      return :unsupported if node.projections.size != 1

      select = node.projections[0]
      select = select.name if select.respond_to?(:name)
      return :unsupported if select != '*'

      parts = [visit(node.source)]

      parts += node.wheres.map {|where| visit(where) }

      parts.include?(:unsupported) ? :unsupported : parts
    end

    def visit_Arel_Nodes_Limit(node)
      {:limit => node.value.to_i}
    end

    def visit_Arel_Nodes_JoinSource(node)
      return :unsupported if !node.left || node.right.any?
      return :unsupported if !node.left.is_a?(Arel::Table)
      visit(node.left)
    end

    def visit_Arel_Table(node)
      {:from => node.name}
    end

    def visit_Arel_Nodes_And(node)
      attributes = node.children.map { |child| visit(child) }
      return :unsupported if attributes.include?(:unsupported)
      attributes.sort! { |pair1, pair2| pair1[0].to_s <=> pair2[0].to_s }
      { :attributes => attributes }
    end

    def visit_Arel_Nodes_In(node)
      left = visit(node.left)
      return :unsupported if left != :id

      [left, visit(node.right)]
    end

    def visit_Arel_Nodes_Equality(node)
      right = node.right
      [visit(node.left), right ? visit(right) : nil]
    end

    def visit_Arel_Attributes_Attribute(node)
      self.last_column = column_for(node.name)
      node.name.to_sym
    end

    def literal(node)
      if node == '?'
        column, value = @binds.shift
        value.to_s
      else
        node.to_s
      end
    end

    # only gets used on 1.8.7
    def visit_Arel_Nodes_BindParam(x)
      @binds.shift[1]
    end

    def visit_Array(node)
      node.map {|value| quoted(value) }
    end

    #TODO: We are actually not using this?
    def quoted(node)
      @model_class.connection.quote(node, self.last_column)
    end

    alias :visit_String                :literal
    alias :visit_Fixnum                :literal
    alias :visit_TrueClass             :literal
    alias :visit_FalseClass            :literal
    alias :visit_Arel_Nodes_SqlLiteral :literal
  end
end
