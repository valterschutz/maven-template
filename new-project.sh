#!/usr/bin/env bash
# Creates a new project from the template/ folder next to this script, without Copier.
# The result is the same as `copier copy gh:valterschutz/maven-template <folder>`;
# tests/compare-with-copier.sh checks that. Runs on bash 3.2 (macOS) and Git Bash (Windows).
set -euo pipefail

# Byte-wise regexes and string comparison, so that sorting matches Jinja's `sort`.
export LC_ALL=C

readonly SRC_PATH="gh:valterschutz/maven-template"
readonly ANSWERS_FILE=".copier/maven-template-answers.yml"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_dir="$script_dir/template"

usage() {
  cat <<EOF
Usage: bash new-project.sh [--defaults] [<folder>]

Creates a new project in <folder>, asking for the project details.
  --defaults   Use the default answers instead of asking. Requires <folder>.
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

# Validators print an error message for an invalid answer, and nothing for a valid one.
# Keep them in sync with the validators in copier.yml.

validate_folder() {
  if [[ -z "$1" ]]; then
    echo "The folder name must not be empty."
  elif [[ -e "$1" && ! -d "$1" ]]; then
    echo "$1 already exists and is not a folder."
  elif [[ -d "$1" && -n "$(ls -A "$1")" ]]; then
    echo "The folder $1 already exists and is not empty."
  fi
}

validate_project_name() {
  local blank='^[[:space:]]*$' forbidden='["<&\\]'
  if [[ "$1" =~ $blank ]]; then
    echo "The project name must not be empty."
  elif [[ "$1" =~ $forbidden ]]; then
    echo "The project name must not contain \", <, & or \\."
  fi
}

validate_group_id() {
  local valid='^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$'
  if ! [[ "$1" =~ $valid ]]; then
    echo "The group ID must be lowercase words separated by dots, each starting with a letter, e.g. com.example."
  fi
}

validate_artifact_id() {
  local valid='^[a-z][a-z0-9]*(-[a-z0-9]+)*$'
  if ! [[ "$1" =~ $valid ]]; then
    echo "The artifact ID must be lowercase words separated by single dashes, starting with a letter, e.g. my-project."
  fi
}

validate_main_class() {
  local valid='^[A-Z][A-Za-z0-9]*$'
  if ! [[ "$1" =~ $valid ]]; then
    echo "The main class must start with an uppercase letter and contain only letters and digits, e.g. Main."
  fi
}

validate_java_version() {
  local number='^[0-9]+$'
  if ! [[ "$1" =~ $number ]]; then
    echo "The Java version must be a whole number, e.g. 21."
  elif ((10#$1 < 21)); then
    echo "The Java version must be 21 or later."
  fi
}

# ask <variable> <question> <default> <validator>
# Sets <variable> to the answer, asking again until the validator accepts it.
ask() {
  local variable="$1" question="$2" default="$3" validator="$4" reply error
  while true; do
    if [[ -n "$default" ]]; then
      printf '%s [%s]: ' "$question" "$default"
    else
      printf '%s: ' "$question"
    fi
    IFS= read -r reply || fail "No answer given."
    reply="${reply:-$default}"
    error="$("$validator" "$reply")"
    if [[ -z "$error" ]]; then
      eval "$variable=\$reply"
      return
    fi
    echo "  $error" >&2
  done
}

# Prints a value for the answers file, quoted where YAML would otherwise read it as something
# other than a string. Matches Copier's output for ordinary values.
yaml_scalar() {
  local value="$1"
  local quote="'"
  local first_char_special='^[][?:,{}#&*!|>'"'"'"%@`[:space:]-]' \
    number='^[-+]?(\.?[0-9])[0-9a-zA-Z_.:+-]*$' \
    special_float='^[-+]?\.(inf|Inf|INF|nan|NaN|NAN)$' \
    trailing_space='[[:space:]]$'
  case "$value" in
    "" | "~" | null | Null | NULL | yes | Yes | YES | no | No | NO | true | True | TRUE | \
      false | False | FALSE | on | On | ON | off | Off | OFF | *": "* | *" #"* | *":")
      ;;
    *)
      if ! [[ "$value" =~ $first_char_special || "$value" =~ $number ||
        "$value" =~ $special_float || "$value" =~ $trailing_space ]]; then
        printf '%s' "$value"
        return
      fi
      ;;
  esac
  printf "'%s'" "${value//$quote/$quote$quote}"
}

# Renders a .jinja file to stdout. Supports exactly the Jinja features the template uses:
# the {{...}} placeholders below, and the import-sorting block made up of a {# comment #},
# `{% set pkg = ... %}`, `{% for name in [...] | sort(...) %}`, `import {{ name }};` and
# `{% endfor %}` lines. Fails if anything else is left, so that template changes the script
# doesn't understand are noticed.
render() {
  awk \
    -v project_name="$project_name" \
    -v group_id="$group_id" \
    -v artifact_id="$artifact_id" \
    -v main_class="$main_class" \
    -v java_version="$java_version" \
    -v package_dir="$package_dir" \
    -v package_name="$package_name" '
    # Replaces every occurrence of the literal string `from` in `text` with `to`.
    function replace_all(text, from, to,    result, i) {
      result = ""
      while ((i = index(text, from)) > 0) {
        result = result substr(text, 1, i - 1) to
        text = substr(text, i + length(from))
      }
      return result text
    }
    function substitute(text) {
      text = replace_all(text, "{{project_name}}", project_name)
      text = replace_all(text, "{{group_id}}", group_id)
      text = replace_all(text, "{{artifact_id|replace(\047-\047,\047_\047)}}", substr(package_name, length(group_id) + 2))
      text = replace_all(text, "{{artifact_id}}", artifact_id)
      text = replace_all(text, "{{main_class}}", main_class)
      text = replace_all(text, "{{java_version}}", java_version)
      text = replace_all(text, "{{package_dir}}", package_dir)
      return text
    }
    # Prints the imports in a `{% for name in [...] | sort(case_sensitive=true) -%}` line.
    function print_sorted_imports(line,    list, count, items, names, i, j, name) {
      list = line
      sub(/^[^[]*\[/, "", list)
      sub(/\][^]]*$/, "", list)
      count = split(list, items, ", *")
      for (i = 1; i <= count; i++) {
        name = items[i]
        sub(/^pkg ~ /, package_name, name)
        gsub(/\047/, "", name)
        # Insertion sort; with LC_ALL=C this compares bytes, like Jinja.
        for (j = i - 1; j >= 1 && names[j] > name; j--) {
          names[j + 1] = names[j]
        }
        names[j + 1] = name
      }
      for (i = 1; i <= count; i++) {
        print "import " names[i] ";" eol
      }
    }
    {
      eol = ""
      if (sub(/\r$/, "")) {
        eol = "\r"
      }
    }
    /^\{#.*-#\}$/ || /^\{% set pkg = .* -%\}$/ || /^import \{\{ name \}\};$/ { next }
    /^\{% for name in \[.*\] \| sort\(case_sensitive=true\) -%\}$/ { print_sorted_imports($0); next }
    /^\{% endfor %\}$/ { print eol; next }
    {
      line = substitute($0)
      if (line ~ /\{\{|\{%|\{#/) {
        printf "Unsupported Jinja on line %d of %s: %s\n", FNR, FILENAME, $0 > "/dev/stderr"
        exit 1
      }
      print line eol
    }
  ' "$1"
}

# Renders a path inside template/, e.g. src/main/java/{{package_dir}}/{{main_class}}.java.jinja.
render_path() {
  local path="${1//\{\{package_dir\}\}/$package_dir}"
  path="${path//\{\{main_class\}\}/$main_class}"
  echo "${path%.jinja}"
}

write_answers_file() {
  local commit=""
  # Check for .git first: on a Mac without developer tools, running git opens an install dialog.
  if [[ -e "$script_dir/.git" ]] && command -v git >/dev/null; then
    commit="$(git -C "$script_dir" describe --tags --always)"
  fi
  {
    echo "# Changes here will be overwritten by Copier; NEVER EDIT MANUALLY"
    if [[ -n "$commit" ]]; then
      echo "_commit: $(yaml_scalar "$commit")"
    fi
    echo "_src_path: $SRC_PATH"
    echo "artifact_id: $(yaml_scalar "$artifact_id")"
    echo "group_id: $(yaml_scalar "$group_id")"
    echo "java_version: $java_version"
    echo "main_class: $(yaml_scalar "$main_class")"
    echo "project_name: $(yaml_scalar "$project_name")"
  } >"$1/$ANSWERS_FILE"
}

use_defaults=false
folder=""
for arg in "$@"; do
  case "$arg" in
    --defaults) use_defaults=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) fail "Unknown option $arg. Run with --help for usage." ;;
    *)
      [[ -z "$folder" ]] || fail "Give only one folder. Run with --help for usage."
      folder="$arg"
      ;;
  esac
done

[[ -d "$template_dir" ]] || fail "Can't find $template_dir. Run the script from a full copy of the template repo."

folder="${folder%/}"
if [[ -n "$folder" ]]; then
  error="$(validate_folder "$folder")"
  [[ -z "$error" ]] || fail "$error"
elif $use_defaults; then
  fail "--defaults needs a folder. Run with --help for usage."
else
  ask folder "Which folder should the project be created in?" "" validate_folder
  folder="${folder%/}"
fi

project_name="My Project"
group_id="com.example"
artifact_id="my-project"
main_class="Main"
java_version="21"
if ! $use_defaults; then
  ask project_name "What is your project name? You can include spaces." "$project_name" validate_project_name
  ask group_id "What is your group ID? Use reverse domain notation, e.g. org.codehaus.mojo. Dots are allowed; dashes and underscores are not." "$group_id" validate_group_id
  ask artifact_id "What is your artifact ID? Use dashes, e.g. exec-maven-plugin. Your base package will be <group_id>.<artifact_id> with dashes replaced by underscores." "$artifact_id" validate_artifact_id
  ask main_class "What is your main class called?" "$main_class" validate_main_class
  ask java_version "Which java version do you want to use?" "$java_version" validate_java_version
fi
java_version="$((10#$java_version))"
package_name="$group_id.${artifact_id//-/_}"
package_dir="${package_name//.//}"

# Build the project next to the target folder and move it into place at the end, so that a
# failure doesn't leave a half-finished project behind.
mkdir -p "$(dirname "$folder")"
staging="$(mktemp -d "$(dirname "$folder")/.new-project.XXXXXX")"
trap 'rm -rf "$staging"' EXIT

(cd "$template_dir" && find . -type f ! -name .DS_Store) | while IFS= read -r file; do
  file="${file#./}"
  # The answers file is written separately, since its template is a Copier built-in.
  [[ "$file" == .copier/* ]] && continue
  target="$staging/$(render_path "$file")"
  mkdir -p "$(dirname "$target")"
  if [[ "$file" == *.jinja ]]; then
    render "$template_dir/$file" >"$target"
  else
    cp "$template_dir/$file" "$target"
  fi
done

mkdir -p "$staging/.copier"
write_answers_file "$staging"

[[ ! -d "$folder" ]] || rmdir "$folder"
mv "$staging" "$folder"
chmod "$(umask -S)" "$folder"

echo
echo "Created $project_name in $folder. To run it:"
echo "  cd \"$folder\""
echo "  ./mvnw compile exec:java     (on Windows: mvnw.cmd compile exec:java)"
