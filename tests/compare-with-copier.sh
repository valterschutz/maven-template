#!/usr/bin/env bash
# Checks that new-project.sh creates the same files as Copier, for several sets of answers.
# Needs Copier on the PATH. Uses the working tree, including uncommitted changes.
# The `_commit` and `_src_path` lines of the answers file are not compared: the script always
# records the GitHub source, and Copier records a dirty working tree as an extra commit.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

failures=0

# compare <name> <project_name> <group_id> <artifact_id> <main_class> <java_version>
compare() {
  local name="$1" project_name="$2" group_id="$3" artifact_id="$4" main_class="$5" java_version="$6"
  local copier_out="$work/$name/copier" script_out="$work/$name/script"

  copier copy --quiet --defaults --vcs-ref HEAD \
    -d "project_name=$project_name" -d "group_id=$group_id" -d "artifact_id=$artifact_id" \
    -d "main_class=$main_class" -d "java_version=$java_version" \
    "$repo" "$copier_out" 2>/dev/null
  printf '%s\n' "$project_name" "$group_id" "$artifact_id" "$main_class" "$java_version" |
    bash "$repo/new-project.sh" "$script_out" >/dev/null

  local answers=".copier/maven-template-answers.yml"
  for out in "$copier_out" "$script_out"; do
    grep -v '^_commit:\|^_src_path:' "$out/$answers" >"$out.answers"
    rm "$out/$answers"
    (cd "$out" && find . -type f -perm -u+x | sort) >"$out.executables"
  done

  if diff -r "$copier_out" "$script_out" &&
    diff "$copier_out.answers" "$script_out.answers" &&
    diff "$copier_out.executables" "$script_out.executables"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    failures=$((failures + 1))
  fi
}

compare defaults "My Project" com.example my-project Main 21
# A group ID after "java" in sort order puts the java.util imports first.
compare imports-sorted-after-java "Space Invaders" se.kth space-invaders-2 Game 25
# Project names YAML must quote, and non-ASCII characters.
compare quoted-name "It's: #1 é" org.zz on App 21
compare numeric-name "2048" a.b yes Main 21

if ((failures > 0)); then
  echo "$failures case(s) failed."
  exit 1
fi
