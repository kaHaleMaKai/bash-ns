declare -gA __ARGS__

private; function check-for-absent-arguments() {
  for arg in $required_args; do
    arg-is-not-defined "${arg}" &&
      echo "error: argument '${arg}' was not set. exiting..." >&2 &&
      exit 1
  done
}

private; function require-argument () {
  export required_args="${required_args} ${1}"
}

function require-arguments {
  required_args=''
  while (( "$#" )); do
    require-argument "$1"
    shift
  done
  check-for-absent-arguments
}

# parse an argument into variables
#
# works on arguments of the form
#   assignments: -[-]var=value [value [...]]
#   flags:       -[-]flag
# flags are assigned the value 1
# assignments are evaluated

private; function parse-argument() {
  var_and_vals="$(echo ${1} | sed 's/^\(-*\)\([^=]*\)\(=*\)\(.*\)$/\2 \4/')"

  var="${var_and_vals/ *}"
  vals="${var_and_vals#* }"

  if [[ ! "$var" =~  ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
    echo "expression '$1' is not a valid identifier for a variable" >&2
    exit 1
  fi

  # if arg contains an =-token, we export arg=value
  if [[ ${#vals} -gt 0 && ! "${vals}" =~ ^[[:space:]]*$ ]]; then
    local type='a'
    eval "${var}=''"
    while read -r val; do
      eval "${var}=\$(echo \${${var}} ${val})"
    done <<< $vals
  # else we assume it to be a flag and export it with value 1
  else
    local type='f'
    eval "${var}=1"
  fi
  export "${var}"
  __ARGS__["${var}"]="t:$type v:${!var}"
}

# parse multiple arguments
#
# to be used as 'parse_arguments "$@"'

function parse-arguments() {
  while (( "$#" )); do
    parse-argument "${1}"
    shift
  done
}

function arg-is-defined() {
  [[ "${__ARGS__[$1]+1}" ]]
}

function arg-is-not-defined() {
  [[ "${__ARGS__[$1]-1}" ]]
}

function when-arg() {
  if [[ "$2" = 'then' ]]; then
    arg-is-defined "$1" && ${@:3}
  fi
}

function when-not-arg() {
  if [[ "$2" = 'then' ]]; then
    arg-is-defined "$1" || ${@:3}
  fi
}

function type-of-arg() {
  echo "${__ARGS__[$1]:2:1}"
}

function val-of-arg() {
  echo "${__ARGS__[$1]#* v:}"
}

function ascii-ts() {
  date +'%Y-%m-%d %H:%M:%S' "$@"
}

function unix-to-ascii() {
  helpers.ascii-ts --date="@${*}"
}

function ascii-to-unix() {
  helpers.unix-ts --date="${*}"
}

function ascii-date() {
  date +'%Y-%m-%d' "$@"
}

function ascii-time() {
  date +'%H:%M:%S' "$@"
}

function unix-ts() {
  date +'%s' "$@"
}

function is-ascii-date() {
  echo "$*" |
    egrep '(19[7-9][0-9]|2[0-2][0-9][0-9])-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[01])' >/dev/null 2>&1
}

function is-ascii-time() {
  echo "$*" |
    egrep '([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]' >/dev/null 2>&1
}

function is-ascii-ts() {
  date="$(echo $* | cut -d' ' -f1)"
  time="$(echo $* | cut -d' ' -f2)"
  is-ascii-date "$date" && is-ascii-time "$time"
}

# TODO: function date-diff, taking care of ascii/unix-ts conversion before subtraction etc.
  #lhs=$(ascii-to-unix "${1}")
  #rhs=$(ascii-to-unix "${2}")
  #ascii-time --date="$(( diff % 86400 ))"
#}

#function datediff() {
  #lhs=$(ascii-to-unix "${1}")
  #rhs=$(ascii-to-unix "${2}")
  #diff="$(( lhs - rhs ))"
  #days="$(( diff / 86400 ))"
  #echo "${days}"
#}

function register-flag() {
  flag="$(echo ${1} | sed 's/^\(-*\)\([^=-]*\)\(=*.*\)$/\2/')"
  if [ -z "$flag" ]; then
    exit 1
  fi
  if [ -n $(eval "echo \$${flag}") ]; then
    eval "${flag}=${2}"
  fi
}

function register-flags() {
  default_value="$1"
  shift
  while (( "$#" )); do
    register_flag "$1" "$default_value"
    shift
  done
}

