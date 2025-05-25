#!/bin/bash

# Default Logic Pro Plugin Manager directory location
PLUGIN_DIR="$HOME/Library/Application Support/Logic/Plugin Manager"

# Function to display usage information
show_usage() {
    echo "Usage: $0 <path-to-plugins.xml>"
    echo "Creates folder structure in Logic Pro Plugin Manager based on plugin categories"
    exit 1
}

# Function to create directory if it doesn't exist
create_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Created directory: $dir"
    fi
}

# Check if xmllint is installed
if ! command -v xmllint >/dev/null 2>&1; then
    echo "Error: xmllint is required but not installed."
    echo "Please install it using: brew install libxml2"
    exit 1
}

# Check if input file is provided
if [ $# -ne 1 ]; then
    show_usage
fi

# Check if input file exists
if [ ! -f "$1" ]; then
    echo "Error: File not found: $1"
    exit 1
}

# Create base Plugin Manager directory if it doesn't exist
create_dir "$PLUGIN_DIR"

# Process the XML file and create folders
echo "Processing plugin categories..."

# Create main category folders
while IFS= read -r category; do
    if [ ! -z "$category" ]; then
        # Remove any special characters and spaces for folder name
        safe_category=$(echo "$category" | tr ' ' '_' | tr -cd '[:alnum:]_-')
        if [ ! -z "$safe_category" ] && [ "$safe_category" != "-" ]; then
            create_dir "$PLUGIN_DIR/$safe_category"
            
            # Process subcategories for this main category
            plugin_name=$(echo "$category" | sed 's/[^[:alnum:]]/_/g')
            while IFS= read -r subcategory; do
                if [ ! -z "$subcategory" ] && [ "$subcategory" != "-" ]; then
                    safe_subcategory=$(echo "$subcategory" | tr ' ' '_' | tr -cd '[:alnum:]_-')
                    create_dir "$PLUGIN_DIR/$safe_category/$safe_subcategory"
                fi
            done < <(xmllint --xpath "//dict[mainCategory_1='$category']/subCategory_1/text()" "$1" 2>/dev/null | sort -u)
        fi
    fi
done < <(xmllint --xpath "//dict/mainCategory_1/text()" "$1" 2>/dev/null | sort -u)

# Create manufacturer folders
echo "Creating manufacturer-specific folders..."
while IFS= read -r manufacturer; do
    if [ ! -z "$manufacturer" ]; then
        safe_manufacturer=$(echo "$manufacturer" | tr ' ' '_' | tr -cd '[:alnum:]_-')
        if [ ! -z "$safe_manufacturer" ]; then
            create_dir "$PLUGIN_DIR/Manufacturers/$safe_manufacturer"
        fi
    fi
done < <(xmllint --xpath "//dict/manufacturer/text()" "$1" 2>/dev/null | sort -u)

# Create type-based folders
echo "Creating type-based folders..."
while IFS= read -r type; do
    if [ ! -z "$type" ]; then
        safe_type=$(echo "$type" | tr ' ' '_' | tr -cd '[:alnum:]_-')
        if [ ! -z "$safe_type" ]; then
            create_dir "$PLUGIN_DIR/Types/$safe_type"
        fi
    fi
done < <(xmllint --xpath "//dict/type/text()" "$1" 2>/dev/null | sort -u)

echo "Folder structure creation completed!"