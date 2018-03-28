# frozen_string_literal: true
# Set environment to development unless something else is specified
env = ENV['RAILS_ENV']

root_path = if env != 'development'
              '/docker-rails-starter/current'
            else
              File.expand_path(File.expand_path(File.dirname(__FILE__)) + '/../')
            end

puma_pid = "#{root_path}/tmp/pids/puma.pid"
puma_state = "#{root_path}/tmp/pids/puma.state"
puma_stdout = "#{root_path}/log/puma.stdout.log"
puma_stderr = "#{root_path}/log/puma.stderr.log"
backlog = 1024

directory root_path
stdout_redirect puma_stdout, puma_stderr, true
environment env

rackup  DefaultRackup
pidfile puma_pid
state_path puma_state
prune_bundler
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
bind "tcp://0.0.0.0:3000?backlog=#{backlog}"
if env != 'development'
  # *deadlock detected (fatal)
  workers Integer(ENV['WEB_CONCURRENCY'] || 2)
  threads_count = Integer(ENV['MAX_THREADS'] || 5)
  threads threads_count, threads_count
else
  workers 0
  threads_count = Integer(ENV['MAX_THREADS'] || 2)
  threads threads_count, threads_count
  ::Rails.logger.info 'Sky is the limit!'

  # write stuff to console immediately
  $stderr.sync = true
  $stdout.sync = true
end

on_worker_boot do
  ::ActiveRecord::Base.establish_connection if defined?(::ActiveRecord::Base)
end
