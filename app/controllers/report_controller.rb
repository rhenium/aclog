# -*- coding: utf-8 -*-
class ReportController < ApplicationController
  layout "index"
  def index
    # いんでっくす
  end

  def tweet
    original_id, tweet_id = [get_tweet_id(params[:tweet_id_0]), get_tweet_id(params[:tweet_id_1])].sort

    raise ActionController::BadRequest unless original_id && tweet_id
      # 何かがおかしいよ

    end

    tweet = Tweet.find(tweet_id)
    if tweet
      original = Tweet.find(original_id)
      unless original
        add_issue_stolen(false, tweet_id, original_id)
        return
        # 記録されてなかった
        # どうしよう。どのアカウントのAPIを使うか？
      end

      if original_id < tweet_id
        if iscopy?(original, tweet)
          # 両方記録されており、パクリツイート
          logger.debug("pakuri!!!")
          StolenTweet.register(original, tweet)
          add_issue_stolen(true, tweet_id, original_id)
        else
          # パクリツイートではない（違う）
          logger.debug("not pakuri!")
          add_issue_stolen(false, tweet_id, original_id)
        end
      else
        # パクリツイートではない（新しい）
        logger.debug("not old, new")
      end
    else
      # 記録されてないけど？
      # 403
      logger.debug("not recorded?")
    end
  end

  private
  def get_tweet_id(str)
    case str
    when /^(?:(?:https?:\/\/)?(?:(?:www\.)?twitter\.com|aclog\.koba789\.com)\/(?:i\/|[0-9A-Za-z_]{1,15}\/status(?:es)?\/))?(\d+)/
      $1.to_i
    end
  end

  def iscopy?(original, tweet)
    textr = -> str do
      str.gsub(/([ 　\t\n\r\f]|[\x20\x00-\x20\x0f])/, "")
    end

    textr.call(original.text) == textr.call(tweet.text)
  end

  def add_issue_stolen(resolved, tweet_id, original_id)
    Issue.register(Aclog::Constants::IssueType::TWEET_STOLEN,
                   resolved ? Aclog::Constants::IssueStatus::RESOLVED : Aclog::Constants::IssueStatus::PENDING,
                  {tweet_id: tweet_id, original_id: original_id})
  end
end
