#!/usr/bin/env ruby
# encoding: utf-8

# This script installs dependencies necessary to run the Swift example app.
puts '▸ Installing dependencies for Stripe iOS Example (Simple)'
system('cd Example; carthage bootstrap --platform ios')
puts '▸ Finished installing dependencies for Stripe iOS Example (Simple)'
