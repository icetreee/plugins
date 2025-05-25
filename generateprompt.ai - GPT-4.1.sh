#!/bin/bash

###############################################################################
# Logic Pro Plugin Category Folder Generator
# Parses PlugIns.xml to generate category/subcategory folders for Logic Pro.
# Author: [Your Name], macOS/Logic Pro X specialist
###############################################################################

set -euo pipefail

# Defaults
PLUGIN_XML_DEFAULT="$HOME/Library/Audio/Plug-Ins/PlugIns.xml"
PLUGIN_MANAGER_DIR="$HOME/Library/Audio/Plug-Ins/Components"
LOG_FILE="$HOME/logicpro_plugin_folder_gen.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

print_usage() {
    echo "Usage: $0 [-x <Plugins.xml path>] [-d <destination folder>] [-l <log file>]"
    echo "Defaults:"
    echo "  -x: $PLUGIN_XML_DEFAULT"
    echo "  -d: $PLUGIN_MANAGER_DIR"
    echo "  -l: $LOG_FILE"
}

log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Parse arguments
while getopts "x:d:l:h" opt; do
    case $opt in
        x) PLUGIN_XML="$OPTARG" ;;
        d) PLUGIN_MANAGER_DIR="$OPTARG" ;;
        l) LOG_FILE="$OPTARG" ;;
        h) print_usage; exit 0 ;;
        *) print_usage; exit 1 ;;
    esac
done

PLUGIN_XML="${PLUGIN_XML:-$PLUGIN_XML_DEFAULT}"

log "========== Script started =========="
log "XML file: $PLUGIN_XML"
log "Destination: $PLUGIN_MANAGER_DIR"
log "Log file: $LOG_FILE"

# Check XML file exists and readable
if [ ! -r "$PLUGIN_XML" ]; then
    log "ERROR: Cannot read XML file: $PLUGIN_XML"
    exit 1
fi

# Check destination exists and writable
if [ ! -d "$PLUGIN_MANAGER_DIR" ]; then
    log "ERROR: Destination directory does not exist: $PLUGIN_MANAGER_DIR"
    exit 1
fi
if [ ! -w "$PLUGIN_MANAGER_DIR" ]; then
    log "ERROR: Destination directory not writable. Try running with sudo."
    exit 1
fi

# Temporary file for parsed paths
TMPF=$(mktemp /tmp/logicprofolders.XXXXXX)
trap 'rm -f "$TMPF"' EXIT

# Helper: XML escape for filenames
xml_unescape() {
    local input="$1"
    echo "$input" | sed -e 's/&amp;/\&/g' \
                       -e "s/&apos;/'/g" \
                       -e 's/&quot;/"/g' \
                       -e 's/&gt;/>/g' \
                       -e 's/&lt;/</g'
}

# Parse XML: get unique category/subcategory paths
log "Parsing XML for category/subcategory hierarchy..."

# Use xmllint for robust parsing (macOS built-in)
xmllint --xpath '//dict' "$PLUGIN_XML" 2>/dev/null | \
awk '
BEGIN { RS="</dict>"; IGNORECASE=1 }
/<key>mainCategory_1<\/key>/ {
    # Extract all three main categories and three subcategories
    m1 = ""; m2 = ""; m3 = ""; s1 = ""; s2 = ""; s3 = "";
    if (match($0, /<key>mainCategory_1<\/key>[[:space:]]*<string>([^<]*)<\/string>/, arr)) m1=arr[1];
    if (match($0, /<key>mainCategory_2<\/key>[[:space:]]*<string>([^<]*)<\/string>/, arr)) m2=arr[1];
    if (match($0, /<key>mainCategory_3<\/key>[[:space:]]*<string>([^<]*)<\/string>/, arr)) m3=arr[1];
    if (match($0, /<key>subCategory_1<\/key>[[:space:]]*<string>([^<]*)<\/string>/, arr)) s1=arr[1];
    if (match($0, /<key>subCategory_2<\/key>[[:space:]]*<string>([^<]*)<\/string>/, arr)) s2=arr[1];
    if (match($0, /<key>subCategory_3<\/key>[[:space:]]*<string>([^<]*)<\/string>/, arr)) s3=arr[1];

    # Build all possible nested paths, skipping empty/dash-only
    path = "";
    cats[1]=m1; cats[2]=m2; cats[3]=m3;
    subs[1]=s1; subs[2]=s2; subs[3]=s3;
    for (i=1;i<=3;i++) {
        # Main category
        if (cats[i] != "" && cats[i] != "-") {
            path = (path == "" ? cats[i] : path"/"cats[i]);
            print path;
        }
        # Subcategory under this level
        if (subs[i] != "" && subs[i] != "-") {
            subpath = (path == "" ? subs[i] : path"/"subs[i]);
            print subpath;
        }
    }
}' | sort -u > "$TMPF"

# Read and create folders
log "Generating folders from extracted category paths..."
errors=0
created=0
skipped=0

while IFS= read -r relpath; do
    # Unescape XML entities for folder names
    safe_path=$(xml_unescape "$relpath")

    # Clean up leading/trailing whitespace
    safe_path=$(echo "$safe_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Convert to POSIX-safe path (Logic tolerates most chars, but avoid / in names)
    # Already nested with /, just use as is
    fullpath="$PLUGIN_MANAGER_DIR/$safe_path"

    if [ -z "$safe_path" ]; then
        continue
    fi

    if [ -d "$fullpath" ]; then
        log "SKIP: Folder exists: $fullpath"
        ((skipped++))
    else
        if mkdir -p "$fullpath" 2>/dev/null; then
            log "CREATE: $fullpath"
            ((created++))
        else
            log "ERROR: Failed to create $fullpath"
            ((errors++))
        fi
    fi
done < "$TMPF"

log "Folders created: $created, skipped (already existed): $skipped, errors: $errors"
log "========== Script completed =========="

exit 0