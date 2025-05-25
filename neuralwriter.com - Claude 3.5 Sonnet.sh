#!/bin/bash

# Base directory where plugin folders will be created
# This is typically in the Logic Pro Plugin Manager location
BASE_DIR="$HOME/Music/Audio/Plug-In Manager/Folders"

# Create base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Main categories from the XML file
declare -a CATEGORIES=(
    "Drums"
    "EQ"
    "Harmonics"
    "Keys"
    "Metering"
    "Modulation"
    "Reverb"
    "Sampler"
    "Synth"
    "Tools"
    "Dynamics"
)

# Sub-categories from the XML file
declare -a SUBCATEGORIES=(
    "Image Meter"
    "Multi Meter"
    "Stereo Spreader"
    "Imaging"
    "Tube"
    "Limiter"
)

# Create main category folders
echo "Creating main category folders..."
for category in "${CATEGORIES[@]}"; do
    if [ "$category" != "-" ]; then
        mkdir -p "$BASE_DIR/$category"
        echo "Created folder: $category"
    fi
done

# Create subcategory folders within their respective main categories
echo -e "\nCreating subcategory folders..."

# Metering subcategories
mkdir -p "$BASE_DIR/Metering/Image Meter"
mkdir -p "$BASE_DIR/Metering/Multi Meter"

# Modulation subcategories
mkdir -p "$BASE_DIR/Modulation/Stereo Spreader"
mkdir -p "$BASE_DIR/Modulation/Imaging"

# Harmonics subcategories
mkdir -p "$BASE_DIR/Harmonics/Tube"

# Dynamics subcategories
mkdir -p "$BASE_DIR/Dynamics/Limiter"

echo -e "\nFolder structure creation completed!"