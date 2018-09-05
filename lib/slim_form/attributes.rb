# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_model/type'
module SlimForm
  module Attributes
    extend ActiveSupport::Concern

    included do
      class_attribute :attributes, instance_accessor: false, default: {}

      # simple_form helper
      def type_for_attribute(attr)
        type = self.class.attributes[attr.to_sym]
        ActiveModel::Type.lookup(type)
      end

      # simple_form helper
      def has_attribute?(attr)
        self.class.attributes.has_key?(attr.to_sym)
      end

      def attributes(only: nil, except: nil)
        attributes_hash = self.class.attributes
        attributes_to_map = if only
                              attributes_hash.slice(*Array(only))
                            elsif except
                              attributes_hash.except(*Array(except))
                            else
                              attributes_hash
                            end.keys
        attributes_array = attributes_to_map.map do |attribute|
          [attribute, public_send(attribute)]
        end
        ActiveSupport::HashWithIndifferentAccess[attributes_array]
      end

      private def _default_value(dynamic_default, attr_name)
        case dynamic_default
        when Proc then instance_exec(&dynamic_default)
        when Symbol then public_send(dynamic_default)
        when Hash then _default_value_from_delegate(dynamic_default, attr_name)
        else dynamic_default
        end
      end

      private def _default_value_from_delegate(default_hash, attr_name)
        _method = default_hash[:method] ? default_hash[:method] : attr_name
        public_send(default_hash[:from]).public_send(_method)
      end

      private def sanitize_params(params)
        hash = if params.is_a?(ActionController::Parameters)
                 params.to_unsafe_h
               else
                 params
               end
        hash.slice(*self.class.attributes.keys)
      end
    end

    class_methods do
      def attribute(
        attr_name,
        type = :string,
        default: nil,
        required: true,
        unique_for: nil
      )
        attributes[attr_name.to_sym] = type
        define_attribute_readers(attr_name, type, default)
        define_attribute_writer(attr_name, type)
        define_attribute_validators(attr_name, required, unique_for)
      end

      private def define_attribute_validators(attr_name, required, unique_for)
        validates(attr_name, presence: true) if required
        case unique_for
        when Proc, Symbol
          validates(attr_name, uniqueness: { resource: unique_for })
        when NilClass
        else validates(attr_name, uniqueness: { resource_class: unique_for })
        end
      end

      private def define_attribute_readers(attr_name, type, default)
        define_attribute_reader(attr_name, type, default)
        alias_method("#{attr_name}?".to_sym, attr_name) if type == :boolean
      end

      private def define_attribute_reader(attr_name, type, default)
        i_attr = "@#{attr_name}"
        define_method(attr_name) do
          if instance_variable_defined?(i_attr)
            return instance_variable_get(i_attr)
          end
          raw_value = _default_value(default, attr_name)
          value = ActiveModel::Type.lookup(type).cast(raw_value)
          instance_variable_set(i_attr, value)
        end
      end

      private def define_attribute_writer(attr_name, type)
        define_method("#{attr_name}=") do |value|
          typecast_value = ActiveModel::Type.lookup(type).cast(value)
          instance_variable_set("@#{attr_name}", typecast_value)
        end
      end
    end
  end
end
