# frozen_string_literal: true

require 'active_record/validations/uniqueness'
class UniquenessValidator < ::ActiveRecord::Validations::UniquenessValidator
  NoResourceOrResourceClassError = Class.new(StandardError)
  InvalidResourceOptError = Class.new(StandardError)

  def initialize(options)
    form_resource_opt = options.delete(:resource)
    form_resource_class = options.delete(:resource_class)
    if [form_resource_opt, form_resource_class].none?
      raise NoResourceOrResourceClassError
    end
    @form_resource_opt = form_resource_opt
    @form_resource_class = form_resource_class
    super
  end

  def validate_each(form, attribute, value)
    @form_resource = if @form_resource_opt&.is_a? Proc
                       form.instance_eval(&@form_resource_opt)
                     elsif @form_resource_opt&.is_a? Symbol
                       form.public_send(@form_resource_opt)
                     else
                       @form_resource_class.new
                     end
    raise InvalidResourceOptError if @form_resource_opt && @form_resource.nil?
    @form_resource_class ||= @form_resource.class
    value = map_enum_attribute(@form_resource_class, attribute, value)
    relation = build_relation(@form_resource_class, attribute, value)
    if @form_resource.persisted?
      if @form_resource_class.primary_key
        relation = relation.where.not(@form_resource_class.primary_key => @form_resource.id_in_database)
      else
        raise UnknownPrimaryKey.new(@form_resource_class, "Can not validate uniqueness for persisted record without primary key.")
      end
    end
    relation = scope_relation(@form_resource, relation)
    relation = relation.merge(options[:conditions]) if options[:conditions]

    if relation.exists?
      error_options = options.except(:case_sensitive, :scope, :conditions)
      error_options[:value] = value

      form.errors.add(attribute, :taken, error_options)
    end
  end
end
