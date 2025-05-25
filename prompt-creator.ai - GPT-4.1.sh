#!/bin/bash

# Script to create Logic Pro Plugin Manager folders based on PlugIns.xml
# Requirements: xmllint, iconv (standard on macOS)
# Usage: ./create_logic_folders.sh /path/to/PlugIns.xml

set -euo pipefail

# Configurable: Destination for Logic Pro Plug-In Manager folders
# Usually: ~/Music/Audio\ Music\ Apps/Plug-In\ Settings/<PluginType>/
# For this script, adjust as needed:
DEST_ROOT="$HOME/Music/Audio Music Apps/Plug-In Settings"

# Path to PlugIns.xml, passed as the first argument
PLUGINS_XML="${1:-PlugIns.xml}"

# Check for required tool
if ! command -v xmllint >/dev/null; then
  echo "Error: xmllint is required but not found. Install Command Line Tools with 'xcode-select --install'."
  exit 1
fi

if [ ! -f "$PLUGINS_XML" ]; then
  echo "Error: PlugIns.xml not found at $PLUGINS_XML"
  exit 1
fi

# Function to sanitize folder names (remove or replace problematic characters)
sanitize() {
  # Remove or replace characters not valid in macOS folder names ("/" and ":")
  echo "$1" | sed 's#[/:]##g'
}

# Parse the XML: extract mainCategory_1, manufacturer, name, and type for each plugin
xmllint --xpath '//dict' "$PLUGINS_XML" | \
awk 'BEGIN{RS="<dict>";FS="\n"} {if($0~/<key>mainCategory_1<.*?>/){print $0}}' | \
while read -r dict; do
  # Extract values with grep; default to "-" if not found
  mainCategory=$(echo "$dict" | grep -A1 '<key>mainCategory_1</key>' | tail -n1 | sed 's/<[^>]*>//g' | xargs)
  manufacturer=$(echo "$dict" | grep -A1 '<key>manufacturer</key>' | tail -n1 | sed 's/<[^>]*>//g' | xargs)
  name=$(echo "$dict" | grep -A1 '<key>name</key>' | tail -n1 | sed 's/<[^>]*>//g' | xargs)
  type=$(echo "$dict" | grep -A1 '<key>type</key>' | tail -n1 | sed 's/<[^>]*>//g' | xargs)

  # Skip if any required field is empty
  if [[ -z "$mainCategory" || -z "$manufacturer" || -z "$name" || -z "$type" ]]; then
    continue
  fi

  # Sanitize folder names
  mainCategory=$(sanitize "$mainCategory")
  manufacturer=$(sanitize "$manufacturer")
  name=$(sanitize "$name")
  type=$(sanitize "$type")

  # Build folder path: DEST_ROOT/<type>/<mainCategory>/<manufacturer>/<name>
  folder_path="$DEST_ROOT/$type/$mainCategory/$manufacturer/$name"

  # Check and create folder if it does not exist
  if [ ! -d "$folder_path" ]; then
    mkdir -p "$folder_path" && \
    echo "Created: $folder_path"
  else
    echo "Exists:  $folder_path"
  fi
done

echo "Folder creation complete."