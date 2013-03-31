Receiver::Worker.spawn!({:working_dir => Rails.root,
               :pid_file => File.join(Rails.root, "tmp", "pids", "#{Rails.env}.receiver.pid"),
               :log_file => File.join(Rails.root, "log", "#{Rails.env}.receiver.log"),
               :sync_log => true,
               :singleton => true})

