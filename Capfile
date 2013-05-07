load 'deploy'
load 'config/deploy'
load 'deploy/assets'

require 'bundler/capistrano'
require 'deploy_bunny'

after 'deploy:finalize_update' do
  configuration.export_environment
  errbit.symlink_configs
end

before 'deploy:assets:precompile' do
  set :real_rake, fetch(:rake)
  set :rake, "#{app_env} #{real_rake}"
end

after 'deploy:assets:precompile' do
  set :rake, fetch(:real_rake)
end

namespace :deploy do
  desc 'Start application.'
  task :start, :roles => [:app, :cron] do
    unicorn.start
  end

  desc 'Stop application.'
  task :stop, :roles => [:app, :cron] do
    unicorn.stop
  end

  desc 'Restart application with zero downtime.'
  task :restart, :roles => [:app, :cron, :web] do
    unicorn.soft_restart
  end

  desc 'Completely restart application (with downtime).'
  task :force_restart, :roles => [:app, :cron] do
    unicorn.hard_restart
  end

  desc 'Show application status.'
  task :status, :roles => :app do
    unicorn.status
  end
end

namespace :errbit do

  ## TODO: Make it get configs from some secret repo

  task :setup_configs do
    shared_configs = File.join(shared_path,'config')
    run "mkdir -p #{shared_configs}"

    # Generate unique secret token
    run %Q{if [ ! -f #{shared_configs}/secret_token.rb ]; then
      cd #{current_release};
      echo "Errbit::Application.config.secret_token = '$(bundle exec rake secret)'" > #{shared_configs}/secret_token.rb;
    fi}.compact
  end

  task :symlink_configs do
    errbit.setup_configs
    shared_configs = File.join(shared_path,'config')
    release_configs = File.join(release_path,'config')
    run("ln -nfs #{shared_configs}/secret_token.rb #{release_configs}/initializers/secret_token.rb")
  end
end

namespace :db do
  desc "Create the indexes defined on your mongoid models"
  task :create_mongoid_indexes do
    app_env "#{bundle_exec} rake db:mongoid:create_indexes"
  end

  desc "Clear resolved tasks"
  task :clear_resolved do
    app_env "#{bundle_exec} rake errbit:db:clear_resolved"
  end

  desc "Migrate database"
  task :migrate do
    app_env "#{bundle_exec} rake db:migrate"
  end
end
