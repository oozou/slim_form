# frozen_string_literal: true

require 'active_support/concern'
require 'active_model/model'
require 'slim_form/attributes'
require 'slim_form/persistence'
require 'slim_form/resource'
module SlimForm
  module Form
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include SlimForm::Attributes
      include SlimForm::Persistence
      include SlimForm::Resource

      def initialize(attrs = {}, resource = nil)
        self.public_send("#{self.class.resource_name}=", resource) if resource
        super(attrs)
      end
    end
  end
end
