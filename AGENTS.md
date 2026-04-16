# Development Guidelines - tiny_pixel

**isaac**: The "Intelligent System for Agent Assistant Communications" (I.S.A.A.C) is my personal digital assistant built with
Rails, Action Mailbox, and RubyLLM.

## Quick Commands

| Task | Command |
|------|---------|
| Generate | `./bin/rails g [model\|controller\|job\|mailbox]` |
| Test | `./bin/rails t` \| `./bin/rails t test/models/site_test.rb` \| `./bin/rails t --name pattern` |
| Coverage | `COVERAGE=1 ./bin/rails t` |
| Lint | `./bin/rubocop` |
| Auto-fix | `./bin/rubocop -A` |

## Code Style

**Formatting**: Ruby 4, 2-space indentation, Unix line endings (LF)

**Required**:
- Frozen string literals at top of `.rb` files: `# frozen_string_literal: true`
- Snake case naming: `req_1` not `req1`
- No unnecessary comments or tests for built-in validations

**Structure**:
- Callbacks → Enums → Scopes → Validations (in class body)
- Scopes as lambdas: `scope :name, -> { where(...) }`
- Rails exceptions: `ActiveRecord::RecordNotFound`, `ActiveRecord::ValidationError`
- One class per Ruby `.rb` file

**Models**:
- Inherit from `ApplicationRecord` (main) or `AnalyticsRecord` (analytics-only)
- Use explicit foreign/primary keys when needed
- Use `self.table_name` only if non-standard

**Controllers**: RESTful conventions with strong parameters
**Views**: Render JSON or HTML per endpoint purpose
