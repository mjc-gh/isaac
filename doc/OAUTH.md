# OAuth Integration Guidelines

Concise reference for integrating OAuth providers (OmniAuth) with encrypted credential storage.

## Core Philosophy

- **Minimal configuration**: Environment variables, one initializer
- **Secure by default**: Encrypted access and refresh tokens
- **Find-or-initialize pattern**: Update tokens without duplicates
- **Test-friendly**: OmniAuth test mode for clean integration tests

## OmniAuth Setup

### Configuration (`config/initializers/omniauth.rb`)

```ruby
# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :provider_name,
           Environ["PROVIDER_CLIENT_ID"],
           Environ["PROVIDER_CLIENT_SECRET"],
           scope: ["scope_1", "scope_2"],
           access_type: "offline",
           prompt: "consent"
rescue Environ::MissingEnvVar
  raise unless Rails.env.test?
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
```

**Why:**
- `access_type: "offline"` requests refresh token
- `prompt: "consent"` ensures refresh token is always returned
- Rescue for test mode allows tests to run without env vars
- `allowed_request_methods = [:post]` enables POST initiation with CSRF protection

### Encrypted Credentials (`config/application.rb`)

```ruby
config.active_record.encryption.primary_key = Environ["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
config.active_record.encryption.deterministic_key = Environ["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
config.active_record.encryption.key_derivation_salt = Environ["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
```

Store in `.env.sh` or deployment secrets.

### Routes (`config/routes.rb`)

```ruby
get "auth/failure", to: "oauth_callbacks#failure", as: :oauth_failure
get "auth/:provider/callback", to: "oauth_callbacks#create", as: :oauth_callback
```

OmniAuth intercepts POST to `/auth/google_oauth2` and redirects to `/auth/google_oauth2/callback`.

## Controller Pattern

### Callback Handler

```ruby
# app/controllers/users/oauth_callbacks_controller.rb
module Users
  class OauthCallbacksController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create]
    before_action :require_authentication

    def create
      auth_hash = request.env["omniauth.auth"]
      provider = auth_hash["provider"]

      auth_token = current_user.auth_tokens.find_or_initialize_by(provider:)
      auth_token.access_token = auth_hash.dig("credentials", "token")
      auth_token.refresh_token = auth_hash.dig("credentials", "refresh_token")
      auth_token.scopes = ["scope_url"]

      if auth_token.save
        redirect_to path, notice: "Connected successfully"
      else
        redirect_to path, alert: "Connection failed"
      end
    end

    def failure
      redirect_to path, alert: "OAuth error: #{params[:message]}"
    end
  end
end
```

**Why:**
- `skip_before_action :verify_authenticity_token` - OAuth provider returns to callback, CSRF protection handled by OmniAuth
- `find_or_initialize_by(provider:)` - Updates existing tokens, prevents duplicates
- `auth_hash.dig()` - Safe access to nested OAuth response

### Token Management Controller

```ruby
# app/controllers/users/auth_tokens_controller.rb
module Users
  class AuthTokensController < ApplicationController
    before_action :require_authentication
    before_action :set_auth_token, only: [:destroy]

    def index
      @auth_tokens = current_user.auth_tokens
    end

    def destroy
      @auth_token.destroy
      redirect_to users_auth_tokens_url, notice: "Disconnected", status: :see_other
    end

    private

    def set_auth_token
      @auth_token = current_user.auth_tokens.find(params[:id])
    end
  end
end
```

**Why:**
- `current_user.auth_tokens.find()` - Scopes to current user, returns 404 if not found
- User cannot delete other users' tokens

## View Patterns

### OAuth Initiation

```erb
<!-- Use button_to (not link_to) with Turbo disabled -->
<%= button_to "Connect Google Calendar", "/auth/google_oauth2", 
    data: { turbo: false }, class: "btn btn-primary" %>
```

**Why:**
- `button_to` submits a form (POST request)
- `data: { turbo: false }` disables Turbo to allow OAuth redirect flow
- `link_to` with `method: :post` doesn't work reliably with OAuth flow

### Token Management

```erb
<% if @auth_tokens.any? %>
  <table>
    <% @auth_tokens.each do |token| %>
      <tr>
        <td><%= token.provider.titleize %></td>
        <td>
          <%= button_to "Disconnect", users_auth_token_path(token), 
              method: :delete, data: { confirm: "Sure?" }, class: "btn btn-sm btn-danger" %>
        </td>
      </tr>
    <% end %>
  </table>
<% else %>
  <p>No connected accounts.</p>
<% end %>
```

## Testing OAuth Callbacks

### Setup Test Mode

```ruby
class OauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
  end
end
```

### Mock OAuth Response

```ruby
test "create saves auth token" do
  post users_sessions_url, params: { email: user.email }
  token = user.generate_magic_link_token(for: :session)
  get verify_users_sessions_url(token: token)

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    credentials: {
      token: "test_access_token",
      refresh_token: "test_refresh_token"
    }
  )

  assert_difference("AuthToken.count", 1) do
    get "/auth/google_oauth2/callback"
  end

  assert_redirected_to users_auth_tokens_url
  auth_token = user.auth_tokens.last
  assert_equal "test_access_token", auth_token.access_token
end
```

**Why:**
- `OmniAuth.config.test_mode = true` - Bypasses actual OAuth provider
- `OmniAuth.config.mock_auth[:provider]` - Sets mock response
- GET to callback (not POST) - OmniAuth redirects via GET
- Request must be authenticated (user must be logged in)

### Test Failure Cases

```ruby
test "create with invalid credentials shows error" do
  # Sign in user...

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    credentials: { token: nil, refresh_token: "..." }
  )

  get "/auth/google_oauth2/callback"

  assert_redirected_to users_auth_tokens_url
  assert_match "error", flash[:alert]
  # Token won't save due to access_token validation
end
```

### Test Authorization

```ruby
test "user cannot delete another user's token" do
  sign_in user_alice

  delete users_auth_token_path(user_bob_token)

  assert_response :not_found
end
```

## Database Model

### AuthToken

```ruby
# app/models/auth_token.rb
class AuthToken < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token

  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :access_token, presence: true
end
```

**Why:**
- `encrypts` - Stores tokens securely using ActiveRecord encryption
- `uniqueness: { scope: :user_id }` - One token per provider per user
- `validates :access_token` - Prevents invalid tokens (find_or_initialize + save pattern catches this)

### Migration

```ruby
create_table :auth_tokens do |t|
  t.references :user, null: false, foreign_key: true
  t.string :provider, null: false
  t.text :access_token, null: false
  t.text :refresh_token
  t.json :scopes, default: []

  t.timestamps

  t.index [:user_id, :provider], unique: true
end
```

## Environment Variables

```bash
# OAuth Provider Credentials
export ISAAC_GOOGLE_CLIENT_ID="your-client-id"
export ISAAC_GOOGLE_CLIENT_SECRET="your-client-secret"

# Encryption Keys (generate with `bin/rails db:encryption:init`)
export ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="..."
export ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="..."
export ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="..."
```

## Best Practices

### DO
- Skip CSRF only on the callback action
- Use find_or_initialize to update tokens
- Test with OmniAuth.config.test_mode
- Store encrypted tokens in database
- Scope auth tokens to current user
- Use `button_to` with `data: { turbo: false }` for OAuth initiation

### DON'T
- Return POST requests from callback (use GET)
- Store unencrypted tokens
- Test with real OAuth credentials
- Skip authentication check on callback controller
- Delete tokens without user confirmation
- Expose tokens in error messages or logs
