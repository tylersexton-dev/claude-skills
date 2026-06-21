#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATEGORY=""
FLAT=false

usage() {
  echo "Usage: $0 [--category <name>] [--flat]"
  echo ""
  echo "Options:"
  echo "  --category <name>   Install only skills from a specific category"
  echo "                      Categories: code-review, testing, devops, architecture"
  echo "  --flat              Install all skills into ~/.claude/skills/ (no subdirectories)"
  echo ""
  echo "Examples:"
  echo "  $0                          # Install all skills preserving structure"
  echo "  $0 --category testing       # Install only testing skills"
  echo "  $0 --flat                   # Install all skills flat"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --category) CATEGORY="$2"; shift 2 ;;
    --flat) FLAT=true; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

echo "Claude Skills Installer"
echo "======================"
echo ""

# Create skills directory if it doesn't exist
if [[ ! -d "$SKILLS_DIR" ]]; then
  mkdir -p "$SKILLS_DIR"
  echo "Created: $SKILLS_DIR"
fi

installed=0
skipped=0

install_skill() {
  local src="$1"
  local filename
  filename="$(basename "$src")"

  if [[ "$FLAT" == true ]]; then
    local dest="${SKILLS_DIR}/${filename}"
  else
    local rel_path="${src#${REPO_DIR}/skills/}"
    local dest="${SKILLS_DIR}/${rel_path}"
    mkdir -p "$(dirname "$dest")"
  fi

  if [[ -f "$dest" ]]; then
    # Check if installed version is newer
    if [[ "$src" -nt "$dest" ]]; then
      cp "$src" "$dest"
      echo "  Updated: $filename"
      ((installed++))
    else
      ((skipped++))
    fi
  else
    cp "$src" "$dest"
    echo "  Installed: $filename"
    ((installed++))
  fi
}

if [[ -n "$CATEGORY" ]]; then
  src_dir="${REPO_DIR}/skills/${CATEGORY}"
  if [[ ! -d "$src_dir" ]]; then
    echo "Error: Category '${CATEGORY}' not found."
    echo "Available: code-review, testing, devops, architecture"
    exit 1
  fi
  echo "Installing category: ${CATEGORY}"
  echo ""
  while IFS= read -r -d '' file; do
    install_skill "$file"
  done < <(find "$src_dir" -name "*.md" -print0 | sort -z)
else
  echo "Installing all skills..."
  echo ""
  while IFS= read -r -d '' file; do
    install_skill "$file"
  done < <(find "${REPO_DIR}/skills" -name "*.md" -print0 | sort -z)
fi

echo ""
echo "Done. ${installed} installed, ${skipped} already up to date."
echo ""
echo "Invoke any skill in Claude Code:"
echo "  /api-design-reviewer"
echo "  /tdd-enforcer implement FeatureX"
echo "  /incident-responder p1 checkout returning 500s"
