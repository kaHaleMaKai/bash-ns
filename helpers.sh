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

function parse-arguments() {
  while (( "$#" )); do
    arg="$1"
    echo "${arg}" |  grep '^\-\-[a-z_]\+=[a-zA-Z_.0-9\-]\+$' > /dev/null
    if [ $? -eq 0 ]; then
      export $(undash ${arg})
    else
      echo "${arg}" |  grep '^\-\-[a-z_]\+$' > /dev/null
      if [ $? -eq 0 ]; then
        export $(undash ${arg}=1)
      else
        echo "error: could not eval argument '${arg}'. exiting..."
        exit 1
      fi
    fi
    shift
  done
}

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
