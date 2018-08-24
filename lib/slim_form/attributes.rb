# frozen_string_literal: true

require 'active_support/concern'
require 'active_model/type'
module SlimForm
  module Attributes
    extend ActiveSupport::Concern

    included do
      class_attribute :attributes, instance_accessor: false, default: {}

      def type_for_attribute(attr)
        type = self.class.attributes[attr.to_sym]
        ActiveModel::Type.lookup(type)
      end

      def has_attribute?(attr)
        self.class.attributes.has_key?(attr.to_sym)
      end

      def _default_value(dynamic_default)
        return instance_exec(&dynamic_default) if dynamic_default.is_a? Proc
        return public_send(dynamic_default) if dynamic_default.is_a? Symbol
        dynamic_default
      end
    end

    class_methods do
      def attribute(attr, type = :string, default: nil)
        attributes[attr.to_sym] = type
        define_attribute_readers(attr, type, default)
        define_attribute_writer(attr, type)
      end

      private def define_attribute_readers(attr, type, default)
        define_attribute_reader(attr, type, default)
        alias_method("#{attr}?".to_sym, attr) if type == :boolean
        define_raw_attribute_reader(attr, default)
      end

      private def define_attribute_reader(attr, type, default)
        i_attr = "@#{attr}"
        define_method(attr) do
          if instance_variable_defined?(i_attr)
            return instance_variable_get(i_attr)
          end
          value = ActiveModel::Type.lookup(type).cast(_default_value(default))
          instance_variable_set(i_attr, value)
          value
        end
      end

      private def define_raw_attribute_reader(attr, default)
        i_raw_attr = "@raw_#{attr}"
        define_method("raw_#{attr}") do
          if instance_variable_defined?(i_raw_attr)
            return instance_variable_get(i_raw_attr)
          end
          value = _default_value(default)
          instance_variable_set(i_raw_attr, value)
        end
      end

      private def define_attribute_writer(attr, type)
        define_method("#{attr}=") do |value|
          instance_variable_set("@raw_#{attr}", value)
          typecast_value = ActiveModel::Type.lookup(type).cast(value)
          instance_variable_set("@#{attr}" , typecast_value)
        end
      end
    end
  end
end
