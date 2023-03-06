#!/usr/bin/env just --justfile

hello:
  echo "hello world"

# needed when you reclone your repo (submodules may not get cloned automatically)
init_theme:
    git submodule update --init --recursive

# asdasdasd
update_theme:
    git submodule update --remote --merge

new filename="" :
    go run main.go {{filename}}

view:
    open url http://localhost:1313/

update_time:
    #!/usr/bin/env sh
    for file in $(git status --porcelain | awk '{if($1=="M" && $2 ~ /\.md$/) print $2}'); do
        sed -i "s/^update:.*/update: $(date +'%Y-%m-%dT%H:%M:%S%z')/" "$file";
    done
