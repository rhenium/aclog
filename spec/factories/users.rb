FactoryGirl.define do
  factory :user_1, class: User do |f|
    f.id 1326331596
    f.screen_name "aclog_test"
    f.profile_image_url "https://si0.twimg.com/sticky/default_profile_images/default_profile_2_normal.png"
    f.protected false
  end

  factory :user_exists, class: User do |f|
    f.id 15926668
    f.screen_name "toshi_a"
    f.profile_image_url "https://si0.twimg.com/profile_images/3252770797/b462225c334fd35c22581684e98cb10d_normal.png"
    f.protected false
  end

  factory :user_not_exists, class: User do |f|
    f.id 0
    f.screen_name ""
    f.profile_image_url ""
    f.protected false
  end

  factory :user_suspended, class: User do |f|
    f.id 230367516
    f.screen_name "re4k"
    f.profile_image_url "https://si0.twimg.com/profile_images/3211524383/0b9d7fdd3fdf0c122af079fda4a7727a_normal.png"
    f.protected false
  end
end
