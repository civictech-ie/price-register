#!/usr/bin/env bash
# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
MIX_ENV=prod mix assets.deploy

rm -rf "_build"

# Create the release
MIX_ENV=prod mix release

# Run migrations
_build/prod/rel/price_register/bin/price_register eval "PriceRegister.Release.migrate"