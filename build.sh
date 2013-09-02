#!/usr/bin/env bash

git clone git://github.com/sstephenson/rbenv.git rbenv
( cd rbenv && git checkout tags/v0.4.0 )

git clone git://github.com/sstephenson/ruby-build.git rbenv/plugins/ruby-build
( cd rbenv/plugins/ruby-build && git checkout tags/v20130901 )

export RBENV_ROOT="$(pwd)/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
export RUBY_VERSION="1.9.3-p448"
test -z "$(rbenv versions | grep $RUBY_VERSION)" && rbenv install $RUBY_VERSION
eval "$(rbenv init -)"
rbenv shell $RUBY_VERSION

rbenv exec gem install bundler --no-ri --no-rdoc
( cd lib && rbenv exec bundle )
rbenv rehash
