require_relative 'config'

module V1

  module FieldBoost

    # BUG: An unboosted subfield of a boosted parent field does not inherit its parent's boost value

    def self.all
      Config.dpla.fetch('field_boosts', {})
    end

    def self.for_resource(resource)
      all.fetch(resource, {})
    end

    def self.for_field(resource, name)
      for_resource(resource).fetch(name, nil)
    end

    def self.is_boosted?(resource, name)
      !for_field(resource, name).nil?
    end

  end

end
