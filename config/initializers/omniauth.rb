Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id) || ENV["GOOGLE_CLIENT_ID"],
           Rails.application.credentials.dig(:google, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"],
           {
             scope: "email,profile",
             prompt: "select_account"
           }
end

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

if ENV["RAILS_PUBLIC_URL"].present?
  OmniAuth.config.full_host = ENV["RAILS_PUBLIC_URL"]
end
