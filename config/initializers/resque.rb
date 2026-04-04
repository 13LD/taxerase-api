require "resque"
require "resque-scheduler"
require "erb"
require "yaml"

redis_url = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")
Resque.redis = redis_url
Resque.inline = Rails.env.test?
Resque.logger = Rails.logger
Resque.after_fork = proc do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
end

schedule_path = Rails.root.join("config/resque_schedule.yml")
if schedule_path.exist? && ENV["LOAD_RESQUE_SCHEDULE"] == "true"
  schedule = YAML.safe_load(ERB.new(schedule_path.read).result, aliases: true) || {}
  Resque.schedule = schedule
end
