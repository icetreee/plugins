#!/bin/bash

# Script to generate folders inside the Logic Pro Plugin Manager directory based on PlugIns.xml

# Set the path to the PlugIns.xml file as an input argument
PLUGINS_XML="$1"

# Check if the PlugIns.xml file exists
if [ ! -f "$PLUGINS_XML" ]; then
  echo "Error: PlugIns.xml file not found at $PLUGINS_XML"
  exit 1
fi

# Define the Logic Pro Plugin Manager directory.  This may need to be adjusted based on user configuration.
# This is a common location, but it's best to allow the user to configure this if possible.
PLUGIN_MANAGER_DIR="$HOME/Library/Audio/Plug-Ins/Components"

# Check if the Plugin Manager directory exists
if [ ! -d "$PLUGIN_MANAGER_DIR" ]; then
  echo "Error: Logic Pro Plugin Manager directory not found at $PLUGIN_MANAGER_DIR"
  exit 1
fi

# Function to sanitize folder names (remove invalid characters, etc.)
sanitize_folder_name() {
  local name="$1"
  # Replace spaces with underscores, remove special characters, lowercase
  echo "$name" | tr ' ' '_' | sed 's/[^a-zA-Z0-9_.-]//g' | tr '[:upper:]' '[:lower:]'
}

# Parse the PlugIns.xml file using xmllint and xpath to extract plugin information
# Note: This requires xmllint to be installed (usually comes with libxml2)
# Example: brew install libxml2 (on macOS with Homebrew)

# Loop through each plugin entry in the XML
xmllint --xpath '//array/dict' "$PLUGINS_XML" | while read -r plugin_data; do

  # Extract plugin name
  plugin_name=$(echo "$plugin_data" | xmllint --xpath 'string(dict/key[text()="name"]/following-sibling::string[1])' - 2>/dev/null)

  # Extract manufacturer name
  manufacturer=$(echo "$plugin_data" | xmllint --xpath 'string(dict/key[text()="manufacturer"]/following-sibling::string[1])' - 2>/dev/null)

  #Sanitize the names
  plugin_name_sanitized=$(sanitize_folder_name "$plugin_name")
  manufacturer_sanitized=$(sanitize_folder_name "$manufacturer")

  # Create the full path for the plugin folder
  plugin_path="$PLUGIN_MANAGER_DIR/$manufacturer_sanitized/$plugin_name_sanitized"

  # Check if the folder already exists
  if [ -d "$plugin_path" ]; then
    echo "Warning: Folder already exists: $plugin_path"
  else
    # Create the plugin folder
    echo "Creating folder: $plugin_path"
    mkdir -p "$plugin_path"
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create folder: $plugin_path"
    fi
  fi
done

echo "Folder generation complete."
exit 0