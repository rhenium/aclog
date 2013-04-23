FactoryGirl.define do
  factory :tweet do |t|
    sequence(:text){|n| "text_#{n}"}
    sequence(:source){|n| "source_#{n / 2}"}
    sequence(:tweeted_at){|n| Time.at(1360000000 + n * 1000)}
  end
end
