require "yaml"
require "worker_node/unique_channel"
require "worker_node/worker"
require "worker_node/collector_connection"
require "worker_node/user_stream"

module WorkerNode
  Settings = OpenStruct.new(YAML.load_file(File.expand_path("../../settings.yml", __FILE__)))
  def self.logger
    @logger ||= begin
      l = Logger.new(STDOUT)
      l.level = Logger.const_get(Settings.log_level.upcase)
      l
    end
  end
end
