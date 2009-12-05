module Kasket
  module DirtyMixin
    def kasket_dirty_methods(*method_names)
      method_names.each do |method|
        unless method_defined?("without_kasket_update_#{method}")
          alias_method("without_kasket_update_#{method}", method)
          define_method(method) do |*args|
            result = send("without_kasket_update_#{method}", *args)
            clear_kasket_indices
            result
          end
        end
      end
    end

    alias_method :kasket_dirty_method, :kasket_dirty_methods
  end
end
