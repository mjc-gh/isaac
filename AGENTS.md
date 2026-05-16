# Development Guidelines - tiny_pixel

**isaac**: The "Intelligent System for Agent Assistant Communications" (I.S.A.A.C) is my personal digital assistant built with
Rails, Action Mailbox, and RubyLLM.

## Quick Commands

| Task | Command |
|------|---------|
| Generate | `./bin/rails g [model\|controller\|job\|mailbox\|mailer]` |
| Test | `./bin/rails t` \| `./bin/rails t test/models/site_test.rb` \| `./bin/rails t --name pattern` |
| Coverage | `COVERAGE=1 ./bin/rails t` |
| Lint | `./bin/rubocop` |
| Auto-fix | `./bin/rubocop -A` |

## Code Style

**Formatting**: Ruby 4, 2-space indentation, Unix line endings (LF)

**Required**:
- Frozen string literals at top of `.rb` files: `# frozen_string_literal: true`
- Snake case naming: `req_1` not `req1`
- One class per `.rb` file
- Never add unnecessary code comments
- Never raise runtime errors; use exception classes

**Models**:
- Callbacks → Enums → Scopes → Validations (in class body)
- Scopes as lambdas: `scope :name, -> { where(...) }`
- Inherit from `ApplicationRecord` (main) or `AnalyticsRecord` (analytics-only)
- Use explicit foreign/primary keys when needed
- Use `self.table_name` only if non-standard

**Controllers**:
- RESTful conventions with strong parameters
- Prefer resource routing

**Views**:
- Render JSON or HTML per endpoint purpose

**Testing**:
- Prefer less test cases while maximizing code coverage
- Don't test framework features (validations, relations, other declarative APIs)
- Use `Minitest::Mock` for mocking external dependencies (classes, services)
  - Mock instances with `mock = Minitest::Mock.new; mock.expect(:method, return_value, [args])`
  - Use `assert_mock(mock)` to verify expectations
  - Use `Constant.stub :method, mock do ... end` to override a single method for the duration of the block

**Integration Tests**:
- Prefer `assert_select`; never assert against `response.body` for HTML or Turbo Stream actions
- Never use `assert_template`

## References

- **Testing Stack**: Minitest, simplecov (with 100% coverage required), RuboCop-Rails, Brakeman
- **OAuth**: See `doc/OAUTH.md` for OmniAuth patterns, testing strategies, and encrypted credential storage
- **Turbo**: See `doc/TURBO.md` for notes on implementing controllers and views with Turbo
