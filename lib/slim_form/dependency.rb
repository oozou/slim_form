# frozen_string_literal: true

require 'active_support/concern'
module SlimForm
  module Dependency
    extend ActiveSupport::Concern

    class_methods do
      def dependency(
        model,
        as: model.name.underscore,
        id_accessor: true,
        allow_in_params: true,
        required: true
      )
        dependency_name = as.to_sym
        if id_accessor
          i_dependency_name = "@#{dependency_name}"
          dependency_name_id = "#{dependency_name}_id"
          define_method("#{dependency_name}=") do |object|
            instance_variable_set(i_dependency_name, object)
            instance_variable_set("@#{dependency_name_id}", object.id)
          end
          define_method("#{dependency_name}") do
            instance_variable_get(i_dependency_name) ||
              (if public_send(dependency_name_id)
               model.find(public_send(dependency_name_id))
              end)
          end
          if allow_in_params
            attribute(dependency_name_id, :string)
          else
            attr_accessor(dependency_name_id)
          end
        else
          attr_accessor(dependency_name)
        end
        self.validates(dependency_name, presence: true) if required
      end
    end
  end
end
