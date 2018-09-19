# frozen_string_literal: true

require 'active_model/model'
require 'slim_form/attributes'
require 'slim_form/custom_validators'
require 'slim_form/nested_form'
require 'slim_form/persistence'
require 'slim_form/resources'

module SlimForm
  module Form
    extend ActiveSupport::Concern
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include SlimForm::Attributes
    include SlimForm::NestedForm
    include SlimForm::Persistence
    include SlimForm::Resources

    NullParamsError = Class.new(StandardError)

    included do
      attr_accessor :supplied_resources, :supplied_params

      def initialize(params: {}, **resources)
        # if user passes params: nil
        raise NullParamsError unless params
        initialize_nested_forms
        params_hash = hashify(params)
        self.supplied_params = params_hash.dup
        form_resources = sanitize_resources(params_hash, resources)
        form_resources.each do |resource_accessor, object|
          public_send("#{resource_accessor}=", object)
        end
        self.supplied_resources = form_resources.keys.map(&:to_sym)
        form_attributes = sanitize_params(params_hash)
        super(form_attributes)
      end

      private def initialize_nested_forms
        self.class.nested_forms.each do |attr, klass|
          self.send("#{attr}=", klass.new)
        end
      end

      private def sanitize_resources(hash, resources)
        sanitized_resources = resources.symbolize_keys.keep_if do |key, value|
          value.present?
        end
        self.class.nested_forms.keys.each do |key|
          value = hash.delete(key)
          sanitized_resources[key] ||= value if value
        end
        sanitized_resources
      end

      private def sanitize_params(hash)
        hash.keep_if do |key, value|
          self.class.form_attributes.has_key?(key.to_sym) && value.present?
        end
      end

      private def hashify(params)
        if params.is_a?(ActionController::Parameters)
          params.to_unsafe_h
        else
          params
        end.symbolize_keys
      end
    end
  end
end
