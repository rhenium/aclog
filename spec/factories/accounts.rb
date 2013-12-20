FactoryGirl.define do
  factory :account_1, class: Account do |f|
    f.user_id 1326331596
    f.oauth_token "1326331596-ELn8lmw2WnACmBfdrLrqjGTlEsrw2kICXwcKy3Z"
    f.oauth_token_secret "QZIquEKkr0GUgwRu402RskBaGPs7Q00GCfRwjQTdo"
  end

  factory :account_2, class: Account do |f|
    f.user_id 1326331596
    f.oauth_token "1326331596-iguYFYUWruy37dw7687e3GGYDUEYeghgwdguiGE"
    f.oauth_token_secret "v4H646FYRJUT5hvhHJ7fyudfoiGEqXs3erlopnKJb"
  end
end

