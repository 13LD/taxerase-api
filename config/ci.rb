# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"
  step "Assets: Build JS", "yarn build"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Yarn vulnerability audit", "yarn audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: Prepare DB", "env RAILS_ENV=test bin/rails db:prepare"
  step "Tests: RSpec", "env RAILS_ENV=test bundle exec rspec"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Run system tests once the app has browser-driven coverage.
  # step "Tests: System", "env RAILS_ENV=test bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
