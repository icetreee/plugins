#!/bin/bash
# Script: generate_logic_plugin_folders.sh
#
# Purpose:
#   Parses a Logic Pro Plugins.xml file, extracts plugin categorization, and
#   creates a folder structure inside the Logic Pro Plugin Manager directory
#   that reflects the plugin organization in the XML.
#
# Usage:
#   ./generate_logic_plugin_folders.sh /path/to/Plugins.xml
#
# Assumptions:
#   - The XML structure is as provided in the sample: a <plist><array> of <dict>s,
#     where each <dict> contains keys such as 'manufacturer', 'mainCategory_1', 'mainCategory_2', 'name'.
#   - Folders will be organized as: $PLUGIN_MANAGER_DIR/Manufacturer/MainCategory1/MainCategory2/PluginName
#   - macOS default Plugin Manager directory is:
#       ~/Library/Audio/Plug-Ins/Logic/PluginManager
#     (create if it doesn't exist)
#   - Requires xmllint (comes with macOS) for XML parsing.
#
# Notes:
#   - Handles invalid XML with a warning and aborts.
#   - Ignores plugins with missing manufacturer or name fields.
#   - Skips folder creation for malformed or incomplete entries, with a warning.
#   - Sanitizes folder names to avoid filesystem issues (removes slashes, colons, etc.).

set -e

# ----------- CONFIGURABLE PARAMETERS -----------
PLUGIN_MANAGER_DIR="$HOME/Library/Audio/Plug-Ins/Logic/PluginManager"
# ----------------------------------------------

INPUT_XML="$1"

# Helper: Print error and exit
fail() {
  echo "Error: $1" >&2
  exit 1
}

# Helper: Sanitize folder names (remove slashes, colons, leading/trailing spaces)
sanitize() {
  echo "$1" | sed 's/[:\/\\]/_/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# --- Step 0: Check dependencies and arguments ---
[ -z "$INPUT_XML" ] && fail "No Plugins.xml file provided. Usage: $0 /path/to/Plugins.xml"
[ ! -f "$INPUT_XML" ] && fail "Input file '$INPUT_XML' does not exist."
command -v xmllint >/dev/null 2>&1 || fail "xmllint is required but not found. Please install it."

# --- Step 1: Validate XML ---
if ! xmllint --noout "$INPUT_XML"; then
  fail "Malformed XML in $INPUT_XML"
fi

# --- Step 2: Ensure Plugin Manager directory exists ---
mkdir -p "$PLUGIN_MANAGER_DIR" || fail "Cannot create/access $PLUGIN_MANAGER_DIR"

# --- Step 3: Parse XML and extract plugin entries ---
# For each plugin, extract: manufacturer, mainCategory_1, mainCategory_2, plugin name
# We'll use xmllint with XPath to get all <dict> entries.
# Note: This assumes the XML is structured as <plist><array><dict>...</dict>...</array></plist>

plugin_count="$(xmllint --xpath 'count(/plist/array/dict)' "$INPUT_XML")"

if [ "$plugin_count" -eq 0 ]; then
  fail "No plugins found in XML."
fi

echo "Found $plugin_count plugins in XML."

for ((i=1;i<=plugin_count;i++)); do
  # Extract relevant fields for this plugin
  manufacturer="$(xmllint --xpath "string(/plist/array/dict[$i]/key[.='manufacturer']/following-sibling::*[1])" "$INPUT_XML" 2>/dev/null)"
  maincat1="$(xmllint --xpath "string(/plist/array/dict[$i]/key[.='mainCategory_1']/following-sibling::*[1])" "$INPUT_XML" 2>/dev/null)"
  maincat2="$(xmllint --xpath "string(/plist/array/dict[$i]/key[.='mainCategory_2']/following-sibling::*[1])" "$INPUT_XML" 2>/dev/null)"
  name="$(xmllint --xpath "string(/plist/array/dict[$i]/key[.='name']/following-sibling::*[1])" "$INPUT_XML" 2>/dev/null)"

  # Sanitize values
  manufacturer="$(sanitize "$manufacturer")"
  maincat1="$(sanitize "$maincat1")"
  maincat2="$(sanitize "$maincat2")"
  name="$(sanitize "$name")"

  # Skip if mandatory fields are missing
  if [ -z "$manufacturer" ] || [ -z "$name" ]; then
    echo "Warning: Plugin entry $i missing manufacturer or name, skipping."
    continue
  fi

  # Construct the folder hierarchy
  folder="$PLUGIN_MANAGER_DIR/$manufacturer"
  [ -n "$maincat1" ] && [ "$maincat1" != "-" ] && folder="$folder/$maincat1"
  [ -n "$maincat2" ] && [ "$maincat2" != "-" ] && folder="$folder/$maincat2"
  folder="$folder/$name"

  # Create the folders (if not already exist)
  if [ ! -d "$folder" ]; then
    mkdir -p "$folder" || echo "Warning: Could not create folder $folder"
    echo "Created: $folder"
  else
    echo "Exists: $folder"
  fi
done

echo "Plugin folder generation complete."

# --- End of script ---