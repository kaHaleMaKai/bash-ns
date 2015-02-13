function import-ns() {
  if [ $# -eq 0 ]; then
    echo "error in function 'ns': no arguments given"
  else
    file="${1/%.sh}.sh"
    shift
    if [[ "$1" == 'as' ]]; then
      shift
    fi
    namespace="$1"
    shift
    cat_file="${1:-}"
  fi

  if [ "${namespace}" = '' ]; then
    source "$file"
  else
    tmp_file="$(mktemp)"
    namespace="${namespace}."
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
  fi
}

function private() { :; }
