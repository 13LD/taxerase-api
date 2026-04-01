module Taxerase
  module Netherlands
    class Profile
      AGE_BRACKETS = {
        "under_aow_age" => {
          label: "Below AOW age",
          aow_eligible: false
        },
        "aow_age_or_older" => {
          label: "AOW age or older",
          aow_eligible: true
        }
      }.freeze

      def self.call(age_bracket:)
        config = AGE_BRACKETS.fetch(age_bracket) do
          raise KeyError, "Unsupported Netherlands age bracket #{age_bracket.inspect}"
        end

        {
          age_bracket: age_bracket,
          aow_eligible: config.fetch(:aow_eligible),
          summary: config.fetch(:label)
        }
      end

      def self.validation_errors(age_bracket:)
        AGE_BRACKETS.key?(age_bracket) ? [] : [ "age_bracket is not supported for the Netherlands calculator" ]
      end
    end
  end
end
