#!/bin/sh
printf '\033c\033]0;%s\a' MapaCitysafe
base_path="$(dirname "$(realpath "$0")")"
"$base_path/CitySafe_linux.x86_64" "$@"
