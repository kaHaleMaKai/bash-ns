set -euo pipefail

[[  -v __NAMESPACES__ ]] ||
  declare -Ag __NAMESPACES__

function import-ns() {
  if [ $# -eq 0 ]; then
    echo "[ERROR] function 'import-ns': no arguments given"
  else
    file="${1/%.sh}.sh"
    shift
    if [[ "$1" == 'as' ]]; then
      shift
    fi
    __NAMESPACE__="$1"

    [[ -n "${__NAMESPACES__[${__NAMESPACE__}]:-}" ]] &&
      echo "[WARNING] namespace '${__NAMESPACE__}' has already been included by file '${__NAMESPACES__[${__NAMESPACE__}]}'" >&2 &&
      return 0

    shift

    if [[ ! -f "$file" ]]; then
      [[ -f "${BASH_NS_PATH:-.}/${file}" ]] &&
        file="${BASH_NS_PATH:-.}/${file}"  ||
        (echo "[ERROR] file ${file} not found. exiting..." >&2 &&
           exit 1)
    fi

    cat_file="${1:-}"
  fi

  if [ "${__NAMESPACE__}" = '' ]; then
    echo "[ERROR] it is forbidden to import directly into global namespace (empty string)" >&2
    exit 1
  else
    tmp_file="$(mktemp)"
    namespace="${__NAMESPACE__}."
    private_token="__${RANDOM}__"
    replace_str=''
    sed_args=''
    set -- $(<"$file" grep -v '^[[:space:]]*private;' |
                      grep -o '\(\<function[[:space:]]\+\<[a-zA-Z_][a-zA-Z0-9_\-]*\>\|\<[a-zA-Z_][a-zA-Z0-9_\-]*[[:space:]]*()\)')

    while (( $# )); do
      if [ "$1" != 'function' -a "$1" != '()' -a "${1:0:2}" != '__' ]; then
        sed_args="${sed_args};s/([^a-zA-Z0-9_.#:\"'/-]|^)(\<${1}\>)([^a-zA-Z0-9_.#/-]|$)/\1${namespace}\2\3/g"
      fi
      shift
    done

    set -- $(<"$file" grep    '^[[:space:]]*private;' |
                      grep -o '\(\<function[[:space:]]\+\<[a-zA-Z_][a-zA-Z0-9_\-]*\>\|\<[a-zA-Z_][a-zA-Z0-9_\-]*[[:space:]]*()\)')

    while (( $# )); do
      if [ "$1" != 'function' -a "$1" != '()' -a "${1:0:2}" != '__' ]; then
        sed_args="${sed_args};s/([^a-zA-Z0-9_.#:\"'/-]|^)(\<${1}\>)([^a-zA-Z0-9_.#:\"'/-]|$)/\1${private_token}\2\3/g"
      fi
      shift
    done
    if [ "$sed_args" != '' ]; then
      if [ "$cat_file" == 'show_source' ]; then
        sedded_file=$(<"$file" sed -r "${sed_args}")
        echo "##################################"
        echo "# ${file}"
        echo "##################################"
        echo ""
        echo "${sedded_file}"

        source <(echo "$sedded_file")
      else
        source <(<"$file" sed -r "${sed_args}")
      fi
    else
      source "$file"
    fi
    
    # save file from which the import occured
    printf -v "__NAMESPACES__[${__NAMESPACE__}]" '%s' "${file}"
  fi
}

function private() { :; }
