#!/usr/bin/env bash

export RBENV_ROOT="$(pwd)/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
export RUBY_VERSION="1.9.3-p448"
eval "$(rbenv init -)"
rbenv shell $RUBY_VERSION
mkdir -p www
( cd lib && bundle exec ruby controller.rb > ../www/index.html )
