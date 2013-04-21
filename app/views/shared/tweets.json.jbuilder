json.array! @items do |json, item|
  json.partial! "shared/partial/tweet", item: item
end

