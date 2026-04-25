module Taxerase
  module RuleStatus
    module_function

    NEEDS_REVIEW = "needs_review".freeze
    NOT_IMPLEMENTED = "not_implemented".freeze

    REVIEWABLE_ASSUMPTION_PATTERNS = [
      /\bnot included\b/i,
      /\bno .+ included\b/i,
      /\bnot modeled\b/i,
      /\bstill pending\b/i,
      /\bexcluded\b/i,
      /\boutside this calculator\b/i,
      /\bassumes you qualify\b/i
    ].freeze

    def needs_review(rule_key:, label:, message:, source_keys: [])
      build(
        status: NEEDS_REVIEW,
        status_label: "Needs review",
        severity: "review",
        rule_key:,
        label:,
        message:,
        source_keys:
      )
    end

    def not_implemented(rule_key:, label:, message:, source_keys: [])
      build(
        status: NOT_IMPLEMENTED,
        status_label: "Not implemented",
        severity: "blocking",
        rule_key:,
        label:,
        message:,
        source_keys:
      )
    end

    def from_assumptions(assumptions)
      Array(assumptions).filter_map.with_index do |message, index|
        next unless reviewable_assumption?(message)

        needs_review(
          rule_key: "assumption_#{index + 1}_#{stable_suffix(message)}",
          label: "Documented rule needs review",
          message: message.to_s
        )
      end
    end

    def reviewable_assumption?(message)
      REVIEWABLE_ASSUMPTION_PATTERNS.any? { |pattern| message.to_s.match?(pattern) }
    end

    def stable_suffix(message)
      message.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "").first(48)
    end

    def build(status:, status_label:, severity:, rule_key:, label:, message:, source_keys:)
      {
        status:,
        status_label:,
        severity:,
        rule_key:,
        label:,
        message:,
        source_keys: Array(source_keys).compact
      }
    end
  end
end
