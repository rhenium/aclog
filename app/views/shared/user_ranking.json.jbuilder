json.array! @usermap do |json, u|
  json.count u[1]
  json.user do |json|
    json.id u[0]
    if @include_user
      json.partial! "shared/partial/user", user: User.cached(u[0])
    end
  end
end
