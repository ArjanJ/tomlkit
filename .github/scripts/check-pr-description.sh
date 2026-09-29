#!/usr/bin/env bash
# Checks that a pull request description fills the template in
# .github/pull_request_template.md. Reads the description from PR_BODY.
# Exit 0 = pass, 1 = fail.
set -u

body="${PR_BODY:-}"
if [ -z "${body//[[:space:]]/}" ]; then
  echo "Error: the PR description is empty." >&2
  exit 1
fi

# Prints the lines of one "## <name>" section without HTML comments and
# blank lines.
section() {
  printf '%s\n' "$body" | awk -v name="$1" '
    /^##[[:space:]]/ {
      heading = tolower($0)
      sub(/^##[[:space:]]+/, "", heading)
      sub(/[[:space:]]+$/, "", heading)
      inside = (heading == tolower(name))
      next
    }
    inside { print }
  ' | sed 's/<!--.*-->//g' | grep -v '^[[:space:]]*$' || true
}

failed=0
for name in "Summary" "Agent Drafting Metadata"; do
  if ! printf '%s\n' "$body" | grep -qiE "^##[[:space:]]+${name}[[:space:]]*$"; then
    echo "Error: missing section: ## ${name}" >&2
    failed=1
  elif [ -z "$(section "$name")" ]; then
    echo "Error: section ## ${name} is empty." >&2
    failed=1
  fi
done

agent=$(section "Agent Drafting Metadata" | grep -iE '^-[[:space:]]*Agent:' | head -1 | sed -E 's/^-[[:space:]]*Agent:[[:space:]]*//I')
if [ -z "${agent// /}" ]; then
  echo "Error: fill in the Agent line under ## Agent Drafting Metadata." >&2
  failed=1
fi

if [ "$failed" -ne 0 ]; then
  exit 1
fi
echo "PR description check passed."
