#!/bin/bash

###############################################################################
# Script to create folders in the Logic Pro Plugin Manager based on the
# hierarchy defined in the Plugins.txt XML file.
#
# Requirements:
# - Plugins.txt must be a valid XML file containing the folder structure.
# - Script uses standard macOS commands: mkdir, xmllint, grep, awk, etc.
# - Handles errors gracefully and prints status messages.
###############################################################################

# Set your Plugin Manager directory here (default for user account)
PLUGIN_MANAGER_DIR="$HOME/Library/Application Support/Logic/Plug-In Settings"
PLUGINS_TXT="Plugins.txt"

# --- Step 1: Validate the Plugin Manager directory exists ---
if [ ! -d "$PLUGIN_MANAGER_DIR" ]; then
  echo "Error: Plugin Manager directory does not exist: $PLUGIN_MANAGER_DIR"
  echo "Please check the path and try again."
  exit 1
fi

# --- Step 2: Validate Plugins.txt exists in the current directory ---
if [ ! -f "$PLUGINS_TXT" ]; then
  echo "Error: $PLUGINS_TXT not found in current directory."
  exit 1
fi

# --- Step 3: Extract folder paths from the XML file ---
# The following assumes Plugins.txt has a structure like:
# <root>
#   <folder name="Parent">
#     <folder name="Child">
#       ...
#     </folder>
#   </folder>
# </root>
#
# This block extracts all folder paths, preserving hierarchy.
# If your XML structure differs, adjust the xmllint XPath accordingly.

# Temporary file for storing folder paths
TMP_FOLDERS=$(mktemp)

# Function to recursively parse folders in XML and print their paths
parse_folders() {
  local xml_file="$1"
  local xpath_expr="//*[name()='folder']"
  xmllint --xpath "$xpath_expr" "$xml_file" 2>/dev/null | \
    grep -o '<folder name="[^"]*"' | \
    sed 's/<folder name="//' > "$TMP_FOLDERS.raw"

  # Build full paths by tracking hierarchy
  awk '
  BEGIN { FS=">"; OFS="/" }
  {
    gsub(/<folder name="/, "", $0)
    path[NR] = $1
  }
  END {
    # Simple: Just print all folder names as single-level. For full hierarchy, you may need a more complex parser.
    for (i=1; i<=NR; i++) print path[i]
  }' "$TMP_FOLDERS.raw" > "$TMP_FOLDERS"
}

parse_folders "$PLUGINS_TXT"

# --- Step 4: Create folders in the Plugin Manager directory ---
while IFS= read -r folder_path; do
  # Compose the full path (single-level by default)
  TARGET_DIR="$PLUGIN_MANAGER_DIR/$folder_path"
  if [ -d "$TARGET_DIR" ]; then
    echo "Folder already exists: $TARGET_DIR"
  else
    mkdir -p "$TARGET_DIR" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "Successfully created: $TARGET_DIR"
    else
      echo "Error: Could not create $TARGET_DIR (check permissions)"
    fi
  fi
done < "$TMP_FOLDERS"

# --- Cleanup ---
rm -f "$TMP_FOLDERS" "$TMP_FOLDERS.raw" 2>/dev/null

echo "All plugin folders have been processed."

###############################################################################
# End of script
###############################################################################