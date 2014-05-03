require "msgpack/rpc/transport/unix"

class Account < ActiveRecord::Base
  ACTIVE = 0; INACTIVE = 1

  belongs_to :user
  scope :active, -> { where(status: Account::ACTIVE) }
  scope :for_node, ->(block_number) { active.where("id % ? = ?", Settings.collector.nodes_count, block_number) }

  def notification?; notification end
  def private?; private end
  def active?; status == Account::ACTIVE end

  def self.create_or_update(hash)
    account = where(user_id: hash[:user_id]).first_or_initialize
    account.oauth_token = hash[:oauth_token]
    account.oauth_token_secret = hash[:oauth_token_secret]
    account.status = Account::ACTIVE
    account.save if account.changed?
    account
  end

  def self.random
    self.active.order("RAND()").first
  end

  def deactivate!
    self.status = Account::INACTIVE
    self.save!

    WorkerManager.update_account(self)
  rescue Aclog::Exceptions::WorkerConnectionError
  end

  def client
    @client ||= Twitter::REST::Client.new(consumer_key: Settings.consumer.key,
                                          consumer_secret: Settings.consumer.secret,
                                          access_token: oauth_token,
                                          access_token_secret: oauth_token_secret)
  end

  def following?(target_id)
    api_friendship?(self.user_id, target_id)
  end

  def followed_by?(source_id)
    api_friendship?(source_id, self.user_id)
  end

  private
  def api_friendship?(source_id, target_id)
    return nil unless source_id.is_a?(Integer)
    return nil unless target_id.is_a?(Integer)

    Rails.cache.fetch("friendship/#{source_id}-#{target_id}", expires_in: 3.days) do
      client.friendship?(source_id, target_id) rescue nil
    end
  end
end
