Receiver::Worker.spawn!({:working_dir => Rails.root,
               :pid_file => File.join(Rails.root, "tmp", "pids", "receiver.pid"),
               :log_file => File.join(Rails.root, "log", "receiver.log"),
               :sync_log => true,
               :singleton => true})

