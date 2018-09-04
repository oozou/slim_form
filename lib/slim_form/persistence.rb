# frozen_string_literal: true

module SlimForm
  module Persistence
    attr_accessor :exception

    def save!
      return false unless valid?
      persist!
      true
    rescue => e
      errors.add(:exception, e.message)
      false
    end
  end
end
