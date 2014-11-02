private; function check-for-absent-arguments() {
  for arg in $required_args; do
    [[ -z "$(eval echo \$$(echo ${arg}))" ]] &&
      echo "error: argument '${arg}' was not set. exiting..." &&
      exit 1
  done
  return 0
}

private; function require-argument () {
  export required_args="${required_args} ${1}"
}

function require-arguments {
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
  var="$(echo ${1} | sed 's/^\(-*\)\([^=-]*\)\(=*.*\)$/\2/')"
  if [[ -z "$var" ]]; then
    echo "expression '$1' is not a valid identifier for a variable" >&2
    exit 1
  fi

  # if arg contains an =-token, we export arg=value
  if [[ "${1}" == *=* ]]; then
    vals="$(echo ${1} | sed 's/\(^-*\)\([^=-]*\)\(=\)\(.*\)/\4/')"
    eval "${var}=''"
    for val in $vals; do
      eval "${var}=\$(echo \${${var}} ${val})"
    done
  # else we assume it to be a flag and export it with value 1
  else
    eval "${var}=1"
  fi
  export "${var}"
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

function ascii-ts() {
  date +'%Y-%m-%d %H:%M:%S' "$@"
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

# TODO: function date-diff, taking care of ascii/unix-ts conversion before subtraction etc.
function diff-ts() {
  lhs="$(date '%s' -d ${1})"
  rhs="$(date '%s' -d ${2})"
  echo "$(( lhs - rhs ))"
}

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
