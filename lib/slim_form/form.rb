# frozen_string_literal: true

require 'active_model/model'
require 'slim_form/attributes'
require 'slim_form/dependency'
require 'slim_form/persistence'
require 'slim_form/resource'
module SlimForm
  class Form
    include ActiveModel::Model
    include SlimForm::Attributes
    include SlimForm::Dependency
    include SlimForm::Persistence
    include SlimForm::Resource

    def initialize(params = {}, **dependencies)
      dependencies.each do |dependency_accessor, object|
        public_send("#{dependency_accessor}=", object)
      end
      form_attributes = sanitize_params(params)
      super(form_attributes)
    end
  end
end
