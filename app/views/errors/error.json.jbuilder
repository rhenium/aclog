json.error do |json|
  json.status response.status
  case @exception
  when Aclog::Exceptions::TweetNotFound
    json.message "ツイートが見つかりませんでした。"
  when Aclog::Exceptions::UserNotFound
    json.message "ユーザーが見つかりませんでした。"
  when Aclog::Exceptions::UserNotRegistered
    json.message "ユーザーは aclog に登録していません。"
  when Aclog::Exceptions::UserProtected
    json.message "ユーザーは非公開です。"
  when Aclog::Exceptions::LoginRequired
    json.message "このページの表示にはログインが必要です。"
  when ActionController::RoutingError
    json.message "このページは存在しません。"
  else
    if response.status == 404
      json.message "Not Found (Unknown)"
    else
      json.message "Internal Error (Unknown)"
    end
  end
  # json.exception @exception.class.to_s
end
