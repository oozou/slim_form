# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
module SlimForm
  module Resource
    extend ActiveSupport::Concern

    included do
      ResourceNameAlreadyDefinedError = Class.new(StandardError)
    end

    class_methods do
      def resource(model, as: model.name.underscore)
        association_name = as.to_sym
        class_attribute(
          :resource_name, instance_accessor: false, default: association_name
        )
        dependency(
          model,
          as: association_name,
          allow_in_params: false,
          required: false
        )
        delegate :id, :persisted?, to: association_name, allow_nil: true
        define_singleton_method(:model_name) { model.model_name }
      end
    end
  end
end
