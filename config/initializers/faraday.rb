# https://github.com/sferik/twitter/blob/2ec6142/lib/twitter/default.rb#L28
Twitter.middleware = Faraday::Builder.new do |builder|
  # Convert file uploads to Faraday::UploadIO objects
  builder.use Twitter::Request::MultipartWithFile
  # Checks for files in the payload
  builder.use Faraday::Request::Multipart
  # Convert request params to "www-form-urlencoded"
  builder.use Faraday::Request::UrlEncoded
  # Handle 4xx server responses
  builder.use Twitter::Response::RaiseError, Twitter::Error::ClientError
  # Parse JSON response bodies using MultiJson
  builder.use Twitter::Response::ParseJson
  # Handle 5xx server responses
  builder.use Twitter::Response::RaiseError, Twitter::Error::ServerError
  # Set Faraday's HTTP adapter
  builder.adapter :typhoeus
end

