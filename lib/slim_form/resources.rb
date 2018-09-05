# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
module SlimForm
  module Resources
    extend ActiveSupport::Concern

    included do
      class_attribute :primary_resource_name, instance_accessor: false
      class_attribute :resources, instance_accessor: false, default: {}
    end

    class_methods do
      def mock_model_name(class_name, namespace = nil)
        model_name = ActiveModel::Name.new(nil, nil, class_name)
        define_method(:model_name) { model_name }
      end

      def primary_resource(
        resource_attr,
        class_name: resource_attr.to_s.classify,
        delegates: nil
      )
        self.primary_resource_name = resource_attr.to_sym
        has_one(
          resource_attr,
          class_name: class_name,
          allow_in_params: false,
          delegates: delegates
        )
        delegate_to_resource(resource_attr.to_sym, [:id, :persisted?])
        define_singleton_method(:model_name) do
          class_name.constantize.model_name
        end
      end

      def has_many()
      end

      def has_one(
        resource_attr,
        class_name: resource_attr.to_s.classify,
        id_accessor: true,
        allow_in_params: true,
        required: true,
        delegates: nil
      )
        resource_attr_sym = resource_attr.to_sym
        klass = class_name.constantize
        configure_resource_accessors(
          klass, resource_attr_sym, id_accessor, allow_in_params, required
        )
        delegate_to_resource(resource_attr_sym, delegates) if delegates
        self.resources[resource_attr_sym] = :has_one
        validates(resource_attr_sym, resource_class: klass)
      end

      private def delegate_to_resource(resource_attr, delegates)
        if delegates.first.is_a?(Array)
          delegates.each { |d| delegate_to_resource(resource_attr, d) }
        end
        delegate_opts = delegates.extract_options!.merge(to: resource_attr)
        delegate(*delegates, delegate_opts)
      end

      private def configure_resource_accessors(
        klass,
        resource_attr,
        id_accessor,
        allow_in_params,
        required
      )
        if id_accessor
          i_resource_attr = "@#{resource_attr}"
          resource_attr_id = "#{resource_attr}_id"
          define_method("#{resource_attr}=") do |object|
            instance_variable_set(i_resource_attr, object)
            instance_variable_set("@#{resource_attr_id}", object.id)
          end
          define_method("#{resource_attr}") do
            instance_variable_get(i_resource_attr) ||
              (if public_send(resource_attr_id)
                klass.find(public_send(resource_attr_id))
              end)
          end
          if allow_in_params
            attribute(resource_attr_id, :string)
            validates(resource_attr_id, presence: true) if required
          else
            attr_accessor(resource_attr_id)
            validates(resource_attr, presence: true) if required
          end
        else
          attr_accessor(resource_attr)
        end
      end
    end
  end
end
