#!/usr/bin/env just --justfile

hello:
  echo "hello world"

# needed when you reclone your repo (submodules may not get cloned automatically)
init_theme:
    git submodule update --init --recursive

update_theme:
    git submodule update --remote --merge

new filename="" :
    go run main.go {{filename}}

view:
    open url http://localhost:1313/