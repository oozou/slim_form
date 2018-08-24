# frozen_string_literal: true

require 'active_support/concern'
require 'slim_form/form'
module SlimForm
  extend ActiveSupport::Concern

  included do
    include Form
  end
end
