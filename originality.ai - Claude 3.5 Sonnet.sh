#!/bin/bash

# Define color codes for output messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory for Logic Pro Plugin Manager
# Note: This is a placeholder path - user should modify as needed
PLUGIN_BASE_DIR="$HOME/Music/Audio/Plug-Ins/Components"

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to create directory if it doesn't exist
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Created directory: $dir"
        else
            print_error "Failed to create directory: $dir"
            return 1
        fi
    else
        echo "Directory already exists: $dir"
    fi
    return 0
}

# Check if base directory exists
if [ ! -d "$PLUGIN_BASE_DIR" ]; then
    print_error "Base plugin directory does not exist: $PLUGIN_BASE_DIR"
    read -p "Would you like to create it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_directory "$PLUGIN_BASE_DIR"
    else
        exit 1
    fi
fi

# Main category directories to create (based on XML analysis)
declare -a CATEGORIES=(
    "Drums"
    "EQ"
    "Dynamics"
    "Harmonics"
    "Keys"
    "Metering"
    "Modulation"
    "Reverb"
    "Sampler"
    "Synth"
    "Tools"
)

# Subcategories mapping (based on XML analysis)
declare -A SUBCATEGORIES=(
    ["Metering"]="Image Meter Multi Meter"
    ["Modulation"]="Stereo Spreader Imaging"
    ["Harmonics"]="Tube"
    ["Dynamics"]="Limiter"
)

echo "Creating plugin category directories..."

# Create main categories
for category in "${CATEGORIES[@]}"; do
    create_directory "$PLUGIN_BASE_DIR/$category"
    
    # Create subcategories if they exist
    if [ ${SUBCATEGORIES[$category]+_} ]; then
        for subcategory in ${SUBCATEGORIES[$category]}; do
            create_directory "$PLUGIN_BASE_DIR/$category/$subcategory"
        done
    fi
done

print_success "Plugin folder structure creation completed!"