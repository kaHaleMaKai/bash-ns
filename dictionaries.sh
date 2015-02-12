#!/bin/bash
source extended-builtins.sh
declare -Ag __HASHMAPS__

private; function calc-hash() {
  md5sum <<< "$*" | awk '{ print "_"$1; }'
}

private; function sh-escape() {
  printf '%q' "$*"
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
  map="$(calc-hash "$1")"
  key="$(sh-escape "$2")"
  eval echo "\"\${${map}['${key}']}\""
}

function get-in() {
  local map_name="$(sh-escape "$1")"
  while [[ $# -gt 2 ]]; do
    shift
    map_name="${map_name}#$(sh-escape "$1")"
  done
  map="$(calc-hash "$map_name")"
  key="$(sh-escape "$2")"
  eval echo "\"\${${map}['${key}']}\""
}

function set() {
  map_name="$(sh-escape "$1")"
  map="$(calc-hash "$map_name")"
  key="$(sh-escape "$2")"
  val="$(sh-escape "$3")"
  printf -v "${map}[${key}]" '%s' "${val}"
}

function set-in() {
  local map_name="$(sh-escape "$1")"
  while [[ $# -gt 3 ]]; do
    shift
    map_name="${map_name}#$(sh-escape "$1")"
  done
  map="$(calc-hash "$map_name")"
  key="$(sh-escape "$2")"
  val="$(sh-escape "$3")"
  printf -v "${map}[${key}]" '%s' "${val}"
}

private; function hset() {
  key="$(sh-escape "$2")"
  val="$(sh-escape "$3")"
  printf -v "${1}[${key}]" '%s' "${val}"
}

function keys() {
  map="$(calc-hash "$1")"
  eval 'for k in '"\"\${!${map}[@]}\""'; do echo "$k"; done'
}

function values() {
  local name="$(sh-escape "$1")"
  local map="$(calc-hash "$name")"
  eval 'for k in '"\"\${${map}[@]}\""'; do echo "$k"; done'
}

function contains() {
  local k
  local map="$(calc-hash "$name")"
  local key="$(sh-escape "$2")"
  eval 'for k in '"\"\${!${map}[@]}\""'; do [[ "$k" == "$key" ]] && return 0; done'
  return 1
}

private; function nnew() {
  if [[ $# -eq 2 ]]; then
    declare -Ag "$hash"
    return 0
  else
    local name="$1"
    local hash="$2"
    declare -Ag "$hash"

    shift; shift

    local key_name="$(sh-escape "$1")"
    local prefixed_name="${name}#${key_name}"
    local key_hash="$(calc-hash "$prefixed_name")"
    hset "$hash" "$key_name" "$key_hash"
    shift
    nnew "$prefixed_name" "$key_hash" "$@"
  fi
}

function dissoc() {
  local name="$(sh-escape "$1")"
  local hash="$(calc-hash "$name")"
  shift
  while (( $# )); do
    key="$(sh-escape "$1")"
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
  map="$(calc-hash "$map_name")"
  shift
  key="$(sh-escape "$1")"
  unset -v "${hash}[${key}]"
}
