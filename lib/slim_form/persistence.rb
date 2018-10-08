# frozen_string_literal: true

module SlimForm
  module Persistence

    def save!
      return false unless valid?
      ActiveRecord::Base.transaction { persist! }
    end
  end
end
