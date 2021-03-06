# frozen_string_literal: true

class ResourceClassValidator < ActiveModel::EachValidator
  UnspecifiedClassError = Class.new(StandardError)

  def initialize(options)
    raise UnspecifiedClassError unless @form_resource_class = options[:with]
    super
  end

  def validate_each(form, attr, resource)
    klass = resource.class
    # This allows submodels to match for STI or other inherited models
    return true if klass <= @form_resource_class
    form.errors.add(
      attr, :invalid_class, { resource_class_name: @form_resource_class.name }
    )
  end
end
