module Taxerase
  module Netherlands
    class ThirtyPercentRuling
      BASIS_CONFIG = {
        "standard_threshold" => {
          label: "Standard salary threshold",
          threshold_key: "thirty_percent_ruling_standard_threshold"
        },
        "under_30_masters" => {
          label: "Under 30 with master's degree",
          threshold_key: "thirty_percent_ruling_under_30_master_threshold"
        },
        "scientific_research" => {
          label: "Scientific research or doctor specialist training",
          threshold_key: nil
        }
      }.freeze

      def self.call(regime:, annual_gross_income:, apply_thirty_percent_ruling:, thirty_percent_ruling_basis:)
        new(
          regime:,
          annual_gross_income:,
          apply_thirty_percent_ruling:,
          thirty_percent_ruling_basis:
        ).call
      end

      def self.validation_errors(apply_thirty_percent_ruling:, thirty_percent_ruling_basis:)
        return [] unless ActiveModel::Type::Boolean.new.cast(apply_thirty_percent_ruling)

        BASIS_CONFIG.key?(normalize_basis(thirty_percent_ruling_basis)) ? [] : [
          "thirty_percent_ruling_basis is not supported for the Netherlands 30% ruling"
        ]
      end

      def self.normalize_basis(thirty_percent_ruling_basis)
        thirty_percent_ruling_basis.to_s.presence || "standard_threshold"
      end

      def initialize(regime:, annual_gross_income:, apply_thirty_percent_ruling:, thirty_percent_ruling_basis:)
        @regime = regime
        @annual_gross_income = BigDecimal(annual_gross_income.to_s)
        @apply_thirty_percent_ruling = ActiveModel::Type::Boolean.new.cast(apply_thirty_percent_ruling)
        @thirty_percent_ruling_basis = self.class.normalize_basis(thirty_percent_ruling_basis)
      end

      def call
        return disabled_result unless apply_thirty_percent_ruling

        {
          enabled: true,
          basis: thirty_percent_ruling_basis,
          basis_label: basis_config.fetch(:label),
          threshold:,
          threshold_met: threshold.zero? || annual_gross_income > threshold,
          salary_cap:,
          capped_income:,
          cap_applied: capped_income < annual_gross_income,
          rate:,
          untaxed_allowance:,
          taxable_employment_income:
        }
      end

      private

      attr_reader :regime, :annual_gross_income, :apply_thirty_percent_ruling, :thirty_percent_ruling_basis

      def disabled_result
        {
          enabled: false,
          basis: "",
          basis_label: nil,
          threshold: BigDecimal("0"),
          threshold_met: true,
          salary_cap: parameter_decimal!("thirty_percent_ruling_salary_cap"),
          capped_income: annual_gross_income,
          cap_applied: false,
          rate: parameter_decimal!("thirty_percent_ruling_rate"),
          untaxed_allowance: BigDecimal("0"),
          taxable_employment_income: annual_gross_income
        }
      end

      def basis_config
        BASIS_CONFIG.fetch(thirty_percent_ruling_basis)
      end

      def threshold
        threshold_key = basis_config[:threshold_key]
        threshold_key ? parameter_decimal!(threshold_key) : BigDecimal("0")
      end

      def salary_cap
        @salary_cap ||= parameter_decimal!("thirty_percent_ruling_salary_cap")
      end

      def capped_income
        @capped_income ||= [ annual_gross_income, salary_cap ].min
      end

      def rate
        @rate ||= parameter_decimal!("thirty_percent_ruling_rate")
      end

      def untaxed_allowance
        @untaxed_allowance ||= begin
          max_allowance = capped_income * rate
          threshold_limited_allowance = [ annual_gross_income - threshold, 0 ].max

          threshold.zero? ? max_allowance : [ max_allowance, threshold_limited_allowance ].min
        end
      end

      def taxable_employment_income
        @taxable_employment_income ||= [ annual_gross_income - untaxed_allowance, 0 ].max
      end

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end
    end
  end
end
