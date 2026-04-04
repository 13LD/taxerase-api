#!/usr/bin/env bash
set -o errexit

bundle install
yarn install --frozen-lockfile
yarn build
bundle exec rails assets:precompile
bundle exec rails assets:clean
