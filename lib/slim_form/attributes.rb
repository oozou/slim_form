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

      def attributes
        attributes_array = self.class.attributes.keys.map do |attribute|
          [attribute, public_send(attribute)]
        end
        ActiveSupport::HashWithIndifferentAccess[attributes_array]
      end

      private def _default_value(dynamic_default)
        return instance_exec(&dynamic_default) if dynamic_default.is_a? Proc
        return public_send(dynamic_default) if dynamic_default.is_a? Symbol
        dynamic_default
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
      def attribute(attr, type = :string, default: nil)
        attributes[attr.to_sym] = type
        define_attribute_readers(attr, type, default)
        define_attribute_writer(attr, type)
      end

      private def define_attribute_readers(attr, type, default)
        define_attribute_reader(attr, type, default)
        alias_method("#{attr}?".to_sym, attr) if type == :boolean
      end

      private def define_attribute_reader(attr, type, default)
        i_attr = "@#{attr}"
        define_method(attr) do
          if instance_variable_defined?(i_attr)
            return instance_variable_get(i_attr)
          end
          value = ActiveModel::Type.lookup(type).cast(_default_value(default))
          instance_variable_set(i_attr, value)
        end
      end

      private def define_attribute_writer(attr, type)
        define_method("#{attr}=") do |value|
          typecast_value = ActiveModel::Type.lookup(type).cast(value)
          instance_variable_set("@#{attr}", typecast_value)
        end
      end
    end
  end
end
