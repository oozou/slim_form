# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
module SlimForm
  module NestedForm
    extend ActiveSupport::Concern

    included do
      class_attribute :nested_forms, instance_accessor: false, default: {}
      class_attribute(
        :required_nested_forms, instance_accessor: false, default: []
      )

      def valid?
        super
        validate_nested_forms
        errors.blank?
      end

      private def validate_nested_forms
        self.class.nested_forms.keys.map do |attr|
          form = public_send(attr)
          next if form_should_be_validated?(form, attr) || form.valid?
          form.errors.details.each do |nested_attr, errors_array|
            errors_array.each do |error_hash|
              errors.add(:"#{attr}.#{nested_attr}", error_hash[:error])
            end
          end
        end
      end

      private def form_should_be_validated?(form, resource_attr)
        blank = form.attributes.values.compact.blank?
        not_required =
          !self.class.required_nested_forms.include?(resource_attr.to_sym)
        return false if blank && not_required
        true
      end

      def read_attribute_for_validation(attribute)
        attribute, nested_attribute = attribute.to_s.split('.', 2)
        if nested_attribute
          public_send(
            attribute
          ).send(
            :read_attribute_for_validation, nested_attribute
          )
        else
          super
        end
      end
    end

    class_methods do
      def nested_form(
        resource_attr,
        class_name: "#{resource_attr.to_s.classify}Form",
        required: true,
        &block
      )
        nested_forms[resource_attr.to_sym] =
          if block_given?
            Class.new do
              include SlimForm::Form
              define_singleton_method :name do
                class_name
              end
              instance_eval(&block)
            end
          else
            class_name.constantize
          end
        configure_nested_form_accessors(resource_attr)
        required_nested_forms << resource_attr.to_sym if required
      end

      private def configure_nested_form_accessors(resource_attr)
        attr_reader(resource_attr)
        define_method("#{resource_attr}=") do |*form_or_args|
          form_class = self.class.nested_forms[resource_attr.to_sym]
          form =
            if form_or_args[0].nil?
              form_class.new
            elsif form_or_args[0].is_a?(form_class)
              form_or_args[0]
            elsif form_or_args[0][:params]
              form_class.new(form_or_args[0])
            else
              form_class.new(params: form_or_args[0])
            end
          instance_variable_set("@#{resource_attr}", form)
        end
      end
    end
  end
end
