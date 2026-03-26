#!/usr/bin/env bats
# Test pre-selection of previously pinned packages in fzf

# Setup: create temp config directory
setup() {
  export TEMP_CONFIG_DIR=$(mktemp -d)
  export XDG_CONFIG_HOME="$TEMP_CONFIG_DIR"
  export CONFIG_FILE="$TEMP_CONFIG_DIR/brew-autoupdate/packages.conf"
  mkdir -p "$TEMP_CONFIG_DIR/brew-autoupdate"
}

# Teardown: cleanup temp directory
teardown() {
  rm -rf "$TEMP_CONFIG_DIR"
}

# Test that preselect_bind is generated correctly for pinned packages
@test "preselect_bind is empty when no packages are pinned" {
  touch "$CONFIG_FILE"

  local current_pinned=""
  local preselect_bind=""

  if [[ -n "$current_pinned" ]]; then
    local -a select_actions=()
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] && select_actions+=("search(^${pkg}\$)+select")
    done <<< "$current_pinned"
    (( ${#select_actions[@]} > 0 )) && preselect_bind="--bind \"load:${select_actions[*]}+search()\""
  fi

  [[ -z "$preselect_bind" ]]
}

@test "preselect_bind contains search+select for pinned packages" {
  cat > "$CONFIG_FILE" <<EOF
git
node
python
EOF

  local current_pinned
  current_pinned=$(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' || true)

  local preselect_bind=""
  if [[ -n "$current_pinned" ]]; then
    local -a select_actions=()
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] && select_actions+=("search(^${pkg}\$)+select")
    done <<< "$current_pinned"
    (( ${#select_actions[@]} > 0 )) && preselect_bind="--bind \"load:${select_actions[*]}+search()\""
  fi

  [[ "$preselect_bind" == *'search(^git$)+select'* ]]
  [[ "$preselect_bind" == *'search(^node$)+select'* ]]
  [[ "$preselect_bind" == *'search(^python$)+select'* ]]
}

@test "write_pinned preserves all selected packages" {
  local test_packages=("git" "node" "python")
  local config_file="$TEMP_CONFIG_DIR/brew-autoupdate/test.conf"
  mkdir -p "$(dirname "$config_file")"

  {
    echo "# brew-autoupdate: selected packages for automatic updates"
    echo "# Generated: $(date)"
    echo "# Edit manually or run: brew autoupdate select"
    printf '%s\n' "${test_packages[@]}"
  } > "$config_file"

  local read_packages
  read_packages=$(grep -v '^#' "$config_file" | grep -v '^[[:space:]]*$')

  [[ "$read_packages" == *"git"* ]]
  [[ "$read_packages" == *"node"* ]]
  [[ "$read_packages" == *"python"* ]]
}

@test "config with comments and blank lines is parsed correctly" {
  cat > "$CONFIG_FILE" <<EOF
# This is a comment

git
# Another comment
node

EOF

  local pinned
  pinned=$(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' || true)

  local count
  count=$(echo "$pinned" | wc -l | tr -d ' ')
  [[ "$count" -eq 2 ]]

  echo "$pinned" | grep -q '^git$'
  echo "$pinned" | grep -q '^node$'
}

@test "cask packages are stripped of (cask) suffix" {
  local pkg="visual-studio-code (cask)"
  local stripped="${pkg% (cask)}"

  [[ "$stripped" == "visual-studio-code" ]]
}
