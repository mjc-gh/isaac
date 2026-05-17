# ISAAC [![CI](https://github.com/mjc-gh/isaac/actions/workflows/ci.yml/badge.svg)](https://github.com/mjc-gh/isaac/actions/workflows/ci.yml) ![GitHub Tag](https://img.shields.io/github/v/tag/mjc-gh/isaac?label=latest)

The "Intelligent System for Agent Assistant Communications" (I.S.A.A.C)
is my personal digital assistant built with Rails, Action Mailbox, and
[RubyLLM](https://rubyllm.com/).

## Development

1. Copy `env.example.sh` to `.env.sh` and fill in values as needed
2. Run `source .env.sh` to load env values

# Deploying

## Prerequisites

- A postmark account, for inbound and outbound emails
- A Google OAuth app for Calendar access
  - If you are using G-Suite, enable the Calendar API service for your
    tenant

## Steps

1. Create a `.kamal/secrets` file with the following contents:
  ```
  KAMAL_REGISTRY_USERNAME=[github user name]
  KAMAL_REGISTRY_PASSWORD=[github API token]

  SECRET_KEY_BASE=[random value]

  ISAAC_GOOGLE_CLIENT_ID=[google oauth app id]
  ISAAC_GOOGLE_CLIENT_SECRET=[google oauth secret]
  ISAAC_MISSION_CONTROL_PASSWORD=[password for mission control; optional]
  ISAAC_OPENROUTER_API_KEY=[openroute API key]
  ISAAC_POSTMARK_API_KEY=[postmark API key]
  ISAAC_SENDER_ADDRESS=isaac@example.com
  RAILS_INBOUND_EMAIL_PASSWORD=[postmark inbound password]
  ```
2. Set some env vars for your servers configuration
  ```
  export KAMAL_PROXY_HOST="isaac.example.com"
  export KAMAL_WEB_HOST="1.2.3.4"
  export KAMAL_VOLUME_PATH="/path/to/volume"
  ```
3. When deploying for the first time, create the DB
  ```
  kamal app exec "bin/rails db:prepare"
  ```
4. Run the following to deploy the latest commit
  ```
  kamal deploy --skip-push --version sha-$(git rev-parse --short HEAD)
  ```
