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
        attr,
        class_name: attr.to_s.classify,
        delegates: nil
      )
        self.primary_resource_name = attr.to_sym
        has_one(
          attr,
          class_name: class_name,
          allow_in_params: false,
          delegates: delegates
        )
        delegate_to_resource(attr.to_sym, [:id, :persisted?])
        define_singleton_method(:model_name) do
          class_name.constantize.model_name
        end
      end

      def has_many()
      end

      def has_one(
        attr,
        class_name: attr.to_s.classify,
        id_accessor: true,
        allow_in_params: true,
        required: true,
        delegates: nil
      )
        attr_sym = attr.to_sym
        klass = class_name.constantize
        configure_resource_accessors(
          klass, attr_sym, id_accessor, allow_in_params, required
        )
        delegate_to_resource(attr_sym, delegates) if delegates
        self.resources[attr_sym] = :has_one
        define_method("#{attr}_supplied?") do
          supplied_resources.include?(attr_sym) ||
            (if id_accessor && allow_in_params
              supplied_params.include?("#{attr_sym}_id".to_sym)
            end)
        end
        validates(
          attr_sym,
          resource_class: klass,
          if: "#{attr}_supplied?".to_sym
        )
      end

      private def delegate_to_resource(attr, delegates)
        if delegates.first.is_a?(Array)
          delegates.each { |d| delegate_to_resource(attr, d) }
        end
        delegate_opts = delegates.extract_options!.merge(to: attr)
        delegate(*delegates, delegate_opts)
      end

      private def configure_resource_accessors(
        klass,
        attr,
        id_accessor,
        allow_in_params,
        required
      )
        if id_accessor
          i_attr = "@#{attr}"
          attr_id = "#{attr}_id"
          define_method("#{attr}=") do |object|
            instance_variable_set(i_attr, object)
            instance_variable_set("@#{attr_id}", object.id)
          end
          define_method("#{attr}") do
            instance_variable_get(i_attr) ||
              (if public_send(attr_id)
                instance_variable_set(
                  i_attr, klass.find(public_send(attr_id))
                )
              end)
          end
          if allow_in_params
            attribute(attr_id, :string)
            validates(attr_id, presence: true) if required
          else
            attr_accessor(attr_id)
            validates(attr, presence: true) if required
          end
        else
          attr_accessor(attr)
        end
      end
    end
  end
end
