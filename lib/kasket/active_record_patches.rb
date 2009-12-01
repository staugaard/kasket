module Kasket
  module FixForAssociationAccessorMethods
    def association_accessor_methods(reflection, association_proxy_class)
      define_method(reflection.name) do |*params|
        force_reload = params.first unless params.empty?
        association = association_instance_get(reflection.name)

        if association.nil? || force_reload
          association = association_proxy_class.new(self, reflection)
          retval = force_reload ? association.reload : association.__send__(:load_target)
          if retval.nil? and association_proxy_class == ActiveRecord::Associations::BelongsToAssociation
            association_instance_set(reflection.name, nil)
            return nil
          end
          association_instance_set(reflection.name, association)
        end

        association.target.nil? ? nil : association
      end

      define_method("loaded_#{reflection.name}?") do
        association = association_instance_get(reflection.name)
        association && association.loaded?
      end

      define_method("#{reflection.name}=") do |new_value|
        association = association_instance_get(reflection.name)

        if association.nil? || association.target != new_value
          association = association_proxy_class.new(self, reflection)
        end

        if association_proxy_class == ActiveRecord::Associations::HasOneThroughAssociation
          association.create_through_record(new_value)
          if new_record?
            association_instance_set(reflection.name, new_value.nil? ? nil : association)
          else
            self.send(reflection.name, new_value)
          end
        else
          association.replace(new_value)
          association_instance_set(reflection.name, new_value.nil? ? nil : association)
        end
      end

      define_method("set_#{reflection.name}_target") do |target|
        return if target.nil? and association_proxy_class == ActiveRecord::Associations::BelongsToAssociation
        association = association_proxy_class.new(self, reflection)
        association.target = target
        association_instance_set(reflection.name, association)
      end
    end
  end
end

ActiveRecord::Base.extend Kasket::FixForAssociationAccessorMethods