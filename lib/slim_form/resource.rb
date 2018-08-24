# frozen_string_literal: true

require 'active_support/concern'
module SlimForm
  module Resource
    extend ActiveSupport::Concern

    included do
      ResourceNameAlreadyDefinedError = Class.new(StandardError)
    end

    class_methods do
      def resource(model)
        if respond_to?(:resource_name) && resource_name.present?
          raise ResourceNameAlreadyDefinedError
        end
        cattr_accessor :resource_name
        model_name = model.name.underscore.to_sym
        self.resource_name = model_name
        attr_writer(model_name)
        define_method(model_name) do
          instance_variable_get("@#{model_name}") ||
            instance_variable_set("@#{model_name}", model.new)
        end
        delegate :id, :persisted?, to: model_name
        define_singleton_method(:model_name) { model.model_name }
      end
    end
  end
end
