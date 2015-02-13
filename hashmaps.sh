set -euo pipefail
declare -Ag __HASHMAPS__

function is-hashmap() {
  [[ "$(declare -p "$1" 2>/dev/null)" =~ 'declare -A' ]]
}

function is-list() {
  [[ "$(declare -p "$1" 2>/dev/null)" =~ 'declare -a' ]]
}

private; function calc-hash() {
  md5sum <<< "$*" | awk '{ print "_"$1; }'
}

private; function sh-escape() {
  printf '%q' "$*"
}

function get-name() {
  local acc="${1:-}"
  shift
  while (( $# )); do
    acc="${acc}#$(sh-escape "${1}")"
    shift
  done
  echo "$acc"
}

function new() {
  for arg in "$@"; do
    local name="$(sh-escape "$1")"
    local hash="$(calc-hash "$name")"
    if [[ ! __HASHMAPS__["$name"] ]]; then
      __HASHMAPS__["$name"]="$hash"
    fi
    declare -Ag "$hash"
  done
}

function new-in() {
  local name="$(sh-escape "$1")"
  local hash="$(calc-hash "$name")"
  if [[ ! __HASHMAPS__["$name"] ]]; then
    __HASHMAPS__["$name"]="$hash"
  fi
  if [[ $# -gt 1 ]]; then
    shift
    nnew "$name" "$hash" "$@"
  else
    declare -Ag "$hash"
  fi
}

function get() {
  local map="$(calc-hash "$1")"
  local key="$(sh-escape "$2")"
  eval echo "\"\${${map}['${key}']}\""
}

function get-in() {
  local map_name="$(sh-escape "$1")"
  while [[ $# -gt 2 ]]; do
    shift
    map_name="${map_name}#$(sh-escape "$1")"
  done
  local map="$(calc-hash "$map_name")"
  local key="$(sh-escape "$2")"
  eval echo "\"\${${map}['${key}']}\""
}

function assoc() {
  local map_name="$(sh-escape "$1")"
  local map="$(calc-hash "$map_name")"
  local key="$(sh-escape "$2")"
  local val="$(sh-escape "$3")"
  printf -v "${map}[${key}]" '%s' "${val}"
}

function str-join() {
  local delim="$1"
  shift
  local acc="$1"
  shift
  while (( $# )); do
    acc="${acc}${delim}${1}"
    shift
  done
  echo "$acc"
}

function decho() {
  echo "+++++++ $@ ++++++++"
}

function assoc-in() {
  local map_name="$(str-join '#' "${@:1:(($#-2))}")"
  local map="$(calc-hash "$map_name")"
  local key="${@:$(($#-1)):1}"
  local val="${@:$(($#))}"
  printf -v "${map}[${key}]" '%s' "${val}"
}

private; function hassoc() {
  local key="$(sh-escape "$2")"
  local val="$(sh-escape "$3")"
  printf -v "${1}[${key}]" '%s' "${val}"
}

function keys() {
  read -r map map_name <<< $(get-hash-and-name "$@")
  eval 'for k in '"\"\${!${map}[@]}\""'; do echo "$k"; done'
}

private; function kkeys() {
  local map="$(calc-hash $1)"
  #eval 'echo "\${!${map}[@]}"'
  eval 'for k in '"\"\${!${map}[@]}\""'; do echo "$k"; done'
}

function values() {
  read -rd '' map map_name <<< $(get-hash-and-name "$@")
  eval 'for v in '"\"\${${map}[@]}\""'; do echo "$v"; done'
}

function contains() {
  local map_name="$(str-join '#' "${@:1:$(($#))}")"
  local map="$(calc-hash "$map_name")"
  local key="$(sh-escape "${@:$(($#))}")"
  local k
  eval 'for k in '"\"\${!${map}[@]}\""'; do [[ "$k" == "$key" ]] && return 0; done'
  return 1
}

private; function nnew() {
  local name="$1"
  local hash="$2"
  declare -Ag "$hash"
  if [[ $# -eq 2 ]]; then
    return 0
  else
    shift; shift
    local key_name="$(sh-escape "$1")"
    local prefixed_name="${name}#${key_name}"
    local key_hash="$(calc-hash "$prefixed_name")"
    hassoc "$hash" "$key_name" "$key_hash"
    shift
    nnew "$prefixed_name" "$key_hash" "$@"
  fi
}

function get-hash-and-name() {
  local name="$(get-name "$@")"
  local hash="$(calc-hash "$name")"
  echo "${hash} ${name}"
}

function remove() {
  if [[ $# -ge 1 ]]; then
    if [[ $# -eq 1 ]]; then
      unset -v __HASHMAPS__["$(sh-escape "$1")"]
    else
      read -r hash name <<< $(get-hash-and-name "${@:1:$(($#-1))}")
      local key="$(sh-escape "${@:$(($#))}")"
      unset -v "${hash}[${key}]"
    fi
    rremove "$(get-name "$@")"
  fi
}

private; function rremove() {
  local arr="$(get-name "$@")"
  local hash="$(calc-hash "$@")"
  for key in $(kkeys "$arr"); do
    local val="$(get "$arr" "$key")"
    is-hashmap "$val" &&
      rremove "${@} ${key}"
  done
  unset -v "$hash"
}

function dissoc() {
  local name="$(sh-escape "$1")"
  local hash="$(calc-hash "$name")"
  shift
  while (( $# )); do
    local key="$(sh-escape "$1")"
    local val="$(get "$name" "$key")"
    is-hashmap "$val" &&
      rremove "${name}#${key}"
    unset -v "${hash}[${key}]"
    shift
  done
}

function dissoc-in() {
  local map_name="$(sh-escape "$1")"
  while [[ $# -gt 2 ]]; do
    shift
    map_name="${map_name}#$(sh-escape "$1")"
  done
  local map="$(calc-hash "$map_name")"
  shift
  local key="$(sh-escape "$1")"
  unset -v "${hash}[${key}]"
}
