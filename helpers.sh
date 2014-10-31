require-argument () {
  export required_args="${required_args} ${1}"
}

function require-arguments() {
  while (( "$#" )); do
    require-argument "$1"
    shift
  done
}

private; function with-arguments() {
  if [ $# -gt 1 ]; then
    func="$1"
    shift
    $func "$@"
  else
    echo "error in function '${func}': no arguments given" >&2
    exit 1
  fi
}

private; function undash() {
  with-arguments \
     echo "${1}" | sed 's/^-\+//g'
}

# parse an argument into variables
#
# works on arguments of the form
#   assignments: -[-]var=value [value [...]]
#   flags:       -[-]flag
# flags are assigned the value 1
# assignments are evaluated

parse-argument() {
  var="$(echo ${1} | sed 's/^\(-*\)\([^=-]*\)\(=*.*\)$/\2/')"
  if [ -z "$var" ]; then
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

parse_arguments() {
  while (($#)); do
    parse_arg "${1}"
    shift
  done
}
# function parse-arguments() {
#   while (( "$#" )); do
#     arg="$1"
#     echo "${arg}" |  grep '^\-\-[a-z_]\+=[a-zA-Z_.0-9\-]\+$' > /dev/null
#     if [ $? -eq 0 ]; then
#       export $(undash ${arg})
#     else
#       echo "${arg}" |  grep '^\-\-[a-z_]\+$' > /dev/null
#       if [ $? -eq 0 ]; then
#         export $(undash ${arg}=1)
#       else
#         echo "error: could not eval argument '${arg}'. exiting..."
#         exit 1
#       fi
#     fi
#     shift
#   done
# }

function check-for-absent-arguments() {
  for arg in $required_args; do
    [[ -z "$(eval echo \$$(echo ${arg}))" ]] &&
      echo "error: argument '${arg}' was not set. exiting..." &&
      exit 1
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

register-flag() {
  flag="$(echo ${1} | sed 's/^\(-*\)\([^=-]*\)\(=*.*\)$/\2/')"
  if [ -z "$flag" ]; then
    exit 1
  fi
  if [ -n $(eval "echo \$${flag}") ]; then
    eval "${flag}=${2}"
  fi
}

register-flags() {
  default_value="$1"
  shift
  while (( $# )); do
    register_flag "$1" "$default_value"
    shift
  done
}
