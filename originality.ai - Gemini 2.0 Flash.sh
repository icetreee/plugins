#!/bin/bash

# Script to create folders inside Logic Pro Plugin Manager based on PlugIns.xml

# Define the path to the PlugIns.xml file
PLUGINS_XML="PlugIns.xml"

# Define the base directory for the Logic Pro Plugin Manager
PLUGIN_MANAGER_DIR="$HOME/Library/Audio/Plug-Ins/Components"

# Check if the PlugIns.xml file exists
if [ ! -f "$PLUGINS_XML" ]; then
  echo "Error: $PLUGINS_XML not found."
  exit 1
fi

# Check if the Plugin Manager directory exists
if [ ! -d "$PLUGIN_MANAGER_DIR" ]; then
  echo "Error: Plugin Manager directory not found: $PLUGIN_MANAGER_DIR"
  exit 1
fi

# Function to extract values from XML using xpath
extract_value() {
  xmllint --xpath "$1" "$PLUGINS_XML" 2>/dev/null | sed 's/<[^>]*>//g' | tr -d '\n'
}

# Function to create a directory and handle errors
create_directory() {
  local dir_name="$1"
  local full_path="$PLUGIN_MANAGER_DIR/$dir_name"

  # Check if the directory already exists
  if [ -d "$full_path" ]; then
    echo "Directory already exists: $dir_name"
    return
  fi

  # Create the directory
  mkdir -p "$full_path"
  if [ $? -eq 0 ]; then
    echo "Successfully created directory: $dir_name"
  else
    echo "Error creating directory: $dir_name"
  fi
}

# Loop through each plugin entry in the XML file
num_plugins=$(xmllint --xpath 'count(//dict)' "$PLUGINS_XML" 2>/dev/null)

for i in $(seq 1 "$num_plugins"); do
  # Extract plugin details
  manufacturer=$(extract_value "//array/dict[$i]/manufacturer/text()")
  name=$(extract_value "//array/dict[$i]/name/text()")

  # Create the manufacturer directory
  if [ ! -z "$manufacturer" ]; then
    create_directory "$manufacturer"
  fi

  # Create the plugin directory inside the manufacturer directory
  if [ ! -z "$manufacturer" ] && [ ! -z "$name" ]; then
    create_directory "$manufacturer/$name"
  fi
done

echo "Script completed."

exit 0