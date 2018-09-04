# frozen_string_literal: true

require 'active_model/model'
require 'slim_form/attributes'
require 'slim_form/persistence'
require 'slim_form/resources'
require 'slim_form/custom_validators'
module SlimForm
  class Form
    include ActiveModel::Model
    include SlimForm::Attributes
    include SlimForm::Persistence
    include SlimForm::Resources

    def initialize(params: {}, **resources)
      resources.each do |resource_accessor, object|
        public_send("#{resource_accessor}=", object)
      end
      form_attributes = sanitize_params(params)
      super(form_attributes)
    end
  end
end
