def load_app_env(path)
  if File.exist?(path)
    File.readlines(path).each do |line|
      _, k, v = /\Aexport\s+([^=]+)=['"]?(.*)['"]?\Z/.match(line).to_a
      ENV[k] = v.gsub(/['"]\Z/, '')
    end
  else
  end
end
load_app_env 'app-env'

worker_processes [ENV['WORKER_PROCESSES_COUNT'].to_i, 2].max

#listen "/tmp/.sock", :backlog => 64
listen ENV['APP_BINDING_PORT'] || 8080, :tcp_nopush => true

pid 'tmp/pids/unicorn.pid'

timeout 30 # nuke workers after 30 seconds

stderr_path 'log/unicorn.stderr.log'
stdout_path 'log/unicorn.stdout.log'

preload_app true

# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

# This is only guaranteed to detect clients on the same host unicorn runs on
check_client_connection false

before_fork do |server, worker|
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = 'tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
