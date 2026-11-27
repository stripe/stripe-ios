#!/bin/bash
# Sourced only by workflows that need Ruby gems. Native tests use Xcode's SPM.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
if [[ ! -x "$(brew --prefix)/opt/ruby@3.3/bin/ruby" ]]; then
    brew install ruby@3.3
fi
ruby_prefix="$(brew --prefix ruby@3.3)"
export PATH="$ruby_prefix/bin:$PATH"
export GEM_HOME="$CI_PRIMARY_REPOSITORY_PATH/vendor/xcode-cloud-gems"
export PATH="$GEM_HOME/bin:$PATH"
bundler_version="$(tail -1 Gemfile.lock | tr -d '[:space:]')"
gem install bundler --version "$bundler_version" --no-document
export BUNDLE_PATH="$CI_PRIMARY_REPOSITORY_PATH/vendor/bundle"
export BUNDLE_FROZEN=true
bundle "_$bundler_version" install --jobs 4 --retry 3
