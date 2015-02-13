source extended-builtins.sh
import-ns hashmaps as maps

private; function get-awk-flavor() {
  flavor="$(awk -W version 2>/dev/null |
              head -n 1)"
  case "$flavor" in
    *[Gg][Nn][Uu]* | *gawk*)identifier='g'
      ;;
    *mawk*) identifier='m'
      ;;
    *nawk*) identifier='n'
      ;;
    *) identifier='a'
      ;;
  esac
  echo $identifier
}

private; function parse() {
  awk \
    'BEGIN { sections_found = 0;
             was_error = 0;
             faulty_line = "";
             faulty_line_nr = -1;
             len = 0;
             cur_section = ""; }
    /^[#;]|^[ \t]*$/ {
        next; }
    /^\[[a-z][a-zA-Z0-9_-]*\][ \t]*/ {
        gsub(/[\[\] \t]/, "", $0);
          cur_section = $0;
          sections[++sections_found] = $0;
          next; }
    /^[a-zA-Z_0-9-][a-zA-Z_0-9-]*[ \t]*=[ \t]*[^ \t][^ \t]*/ {
        if (sections_found == 0) {
          next; }
        eq_token_idx = index($0, "=");
        var = substr($0, 1, eq_token_idx - 2);
        val = substr($0, eq_token_idx + 1);
        sub(/[ \t][ \t]*/, "", var);
        sub(/^[ \t][ \t]*|[ \t][ \t]*$/, "", val);
        if (tolower(val) == "on") {
          args[++len] = cur_section" "var; }
        else if (tolower(val) != "off") {
          args[++len] = cur_section" "var" "val; }
        next; }
    { was_error = 1;
      faulty_line = $0;
      faulty_line_nr = NR;
      exit 1; }

    END { if (was_error == 1) {
          print "[ERROR] in config file, line "faulty_line_nr > "/dev/stderr";
          print "\""faulty_line"\"" > "/dev/stderr"; }
          else {
            for (i = 1; i <= len; ++i) {
              print args[i]; } } }'
}

function print-args() {
  local section="$1"
  local prefix="${2:---}"
  local delim="${3:-=}"
  local key
  for key in $(maps.keys conf "$section"); do
    local val="$(maps.get-in conf "$section" "$key")"
    local ls="${prefix}${key}"
    if [[ -z "$val" ]]; then
      local rs=''
    else
      local rs="${delim}${val}"
    fi
    echo -n "${ls}${rs} "
  done
}

function parser() {
  maps.new conf
  while IFS=$'\n' read line; do
    read -r section var val <<< $line
    maps.new-in conf "$section" "$var"
    maps.assoc-in conf "$section" "$var" "$val"
  done < <(<"$@" parse)
}
