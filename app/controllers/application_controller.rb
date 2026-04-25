class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def validation_error_payload(error)
    payload = { errors: error.errors }
    payload[:rule_statuses] = error.rule_statuses if error.respond_to?(:rule_statuses) && error.rule_statuses.present?
    payload
  end
end
