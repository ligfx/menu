#!/usr/bin/env bash

git clone git://github.com/sstephenson/rbenv.git rbenv
( cd rbenv && git checkout tags/v0.3.0 )

git clone git://github.com/sstephenson/ruby-build.git rbenv/plugins/ruby-build
( cd rbenv/plugins/ruby-build && git checkout tags/v20121204 )

export RBENV_ROOT="$(pwd)/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
test -z "$(rbenv versions | grep 1.8.7-p370)" && rbenv install 1.8.7-p370
eval "$(rbenv init -)"
rbenv shell 1.8.7-p370

rbenv exec gem install bundler --no-ri --no-rdoc
( cd lib && rbenv exec bundle )
rbenv rehash
