module Taxerase
  class UnsupportedRegimeError < StandardError
    attr_reader :errors, :rule_statuses

    def initialize(errors, rule_statuses: [])
      @errors = errors
      @rule_statuses = rule_statuses
      super(errors.join(", "))
    end
  end
end
