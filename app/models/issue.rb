class Issue < ActiveRecord::Base
  def self.register(issue_type, status, data)
    begin
      create!(:issue_type => issue_type, :status => status, :data => Yajl::Encoder::encode(data))
    rescue
      logger.error($!)
      logger.error($@)
    end
  end
end
