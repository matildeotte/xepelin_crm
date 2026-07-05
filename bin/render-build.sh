#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rails db:prepare
