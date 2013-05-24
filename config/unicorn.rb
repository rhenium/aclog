_rails_root = File.expand_path("../../", __FILE__)

worker_processes 4
working_directory _rails_root
listen File.join(_rails_root, "tmp", "sockets", "unicorn.sock")

_log_file = File.join(_rails_root, "log", "unicorn.log")
stderr_path _log_file
stdout_path _log_file

preload_app true

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && old_pid != server.pid
    begin
      Process.kill(:QUIT, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

  if defined?(ActiveSupport::Cache::DalliStore) && Rails.cache.is_a?(ActiveSupport::Cache::DalliStore)
    Rails.cache.reset
    ObjectSpace.each_object(ActionDispatch::Session::DalliStore) {|obj| obj.reset }
  end
end

