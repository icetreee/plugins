#!/bin/bash

# Define the path to the PlugIns.xml file
PLUGINS_XML="PlugIns.xml"

# Define the base directory for Logic Pro plugins
LOGIC_PLUGINS_DIR="$HOME/Library/Audio/Plug-Ins/Components"

# Check if xmllint is installed
if ! command -v xmllint &> /dev/null
then
    echo "xmllint is not installed. Please install it using:"
    echo "brew install libxml2"
    exit 1
fi

# Function to create a directory if it doesn't exist
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    else
        echo "Directory already exists: $dir"
    fi
}

# Parse the XML file and create directories
while IFS= read -r plugin; do
    manufacturer=$(echo "$plugin" | xmllint --xpath "string(dict/manufacturer/text())" -)
    mainCategory=$(echo "$plugin" | xmllint --xpath "string(dict/mainCategory_1/text())" -)

    # Sanitize the manufacturer and mainCategory names to be used as folder names
    manufacturer_name=$(echo "$manufacturer" | sed 's/[^a-zA-Z0-9._-]//g')
    mainCategory_name=$(echo "$mainCategory" | sed 's/[^a-zA-Z0-9._-]//g')

    # Create the manufacturer directory
    manufacturer_dir="$LOGIC_PLUGINS_DIR/$manufacturer_name"
    create_directory "$manufacturer_dir"

    # Create the category directory inside the manufacturer directory
    category_dir="$manufacturer_dir/$mainCategory_name"
    create_directory "$category_dir"

done < <(xmllint --xpath "//array/dict" "$PLUGINS_XML")

echo "Folder creation complete."