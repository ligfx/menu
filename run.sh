#!/usr/bin/env bash

export RBENV_ROOT="$(pwd)/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"
rbenv shell 1.8.7-p370
mkdir -p www
( cd lib && bundle exec ruby controller.rb > ../www/index.html )
