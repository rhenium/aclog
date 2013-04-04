# -*- coding: utf-8 -*-
FactoryGirl.define do
  factory :user_1, class: User do
    id 1326331596
    screen_name "aclog_test"
    name "aclog test"
    profile_image_url "https://si0.twimg.com/sticky/default_profile_images/default_profile_2_normal.png"
    protected false
  end

  factory :user_exists, class: User do
    id 15926668
    screen_name "toshi_a"
    name "name"
    profile_image_url "https://si0.twimg.com/profile_images/3252770797/b462225c334fd35c22581684e98cb10d_normal.png"
    protected false
  end

  factory :user_not_exists, class: User do
    id 0
    screen_name ""
    name ""
    profile_image_url ""
    protected false
  end

  factory :user_suspended, class: User do
    id 230367516
    screen_name "re4k"
    name "ちくわ"
    profile_image_url "https://si0.twimg.com/profile_images/3211524383/0b9d7fdd3fdf0c122af079fda4a7727a_normal.png"
    protected false
  end

  factory :user do |u|
    sequence(:screen_name){|n| "screen_name_#{n}"}
    sequence(:name){|n| "name_#{n}"}
    sequence(:profile_image_url){|n| "https://si0.twimg.com/sticky/default_profile_images/default_profile_#{n % 7}_normal.png"}
    protected false
  end
end
