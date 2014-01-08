Dir.glob(File.expand_path("../apidoc/**/*.rb", __FILE__)) {|file| require file }

module Apidoc
  extend self

  def resources
    @@resources ||= {}
  end

  def reload!
    @@resources = nil
    dir = "#{Rails.root}/app/controllers/"
    Dir.glob("#{dir}**/*.rb") do |path|
      ActiveSupport::Dependencies.load_file path
    end
  end
end
