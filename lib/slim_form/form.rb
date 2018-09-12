# frozen_string_literal: true

require 'active_model/model'
require 'slim_form/attributes'
require 'slim_form/persistence'
require 'slim_form/resources'
require 'slim_form/custom_validators'

module SlimForm
  module Form
    extend ActiveSupport::Concern
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    include SlimForm::Attributes
    include SlimForm::Persistence
    include SlimForm::Resources

    NullParamsError = Class.new(StandardError)

    included do
      attr_accessor :supplied_resources, :supplied_params

      def initialize(params: {}, **resources)
        # if user passes params: nil
        raise NullParamsError unless params
        form_resources = sanitize_resources(resources)
        form_resources.each do |resource_accessor, object|
          public_send("#{resource_accessor}=", object)
        end
        self.supplied_resources = form_resources.keys.map(&:to_sym)
        form_attributes = sanitize_params(params)
        self.supplied_params = form_attributes.keys.map(&:to_sym)
        super(form_attributes)
      end

      private def sanitize_resources(hash)
        hash.keep_if { |key, value| value.present? }
      end

      private def sanitize_params(params)
        hash = if params.is_a?(ActionController::Parameters)
                 params.to_unsafe_h
               else
                 params
               end
        hash.keep_if do |key, value|
          self.class.attributes.has_key?(key.to_sym) && value.present?
        end
      end
    end
  end
end
