## Shell Script: Create Logic Pro Plugin Manager Folders from PlugIns.xml

Below is a shell script that parses your `PlugIns.xml` and creates folders in your Logic Pro Plugin Manager’s directory structure to match the **main categories** detected for each plugin in your XML. This ensures consistency between your XML configuration and your actual plugin folder organization.

### Script: `create_logic_plugin_folders.sh`

```bash
#!/bin/bash

# Path to your PlugIns.xml file (update if needed)
XML_PATH="$HOME/Downloads/PlugIns.xml"

# Path to Logic Pro's AU plugin manager folders (adjust as needed)
# The usual Plugin Manager does not use actual folders, but for custom organization, we'll create them in ~/Music/Audio Music Apps/Plug-In Settings/
TARGET_BASE="$HOME/Music/Audio Music Apps/Plug-In Settings"

# Parse the mainCategory_1 values and create a folder for each
echo "Parsing main categories from PlugIns.xml..."

# Use xmllint to parse mainCategory_1 values, filter out dashes, and deduplicate
CATEGORIES=$(xmllint --xpath '//key[.="mainCategory_1"]/following-sibling::string[1]/text()' "$XML_PATH" | \
  tr '\n' '\0' | \
  xargs -0 -n1 | \
  grep -v '^-$' | \
  sort | \
  uniq)

echo "Will create the following folders:"
echo "$CATEGORIES"
echo

for cat in $CATEGORIES; do
  FOLDER="$TARGET_BASE/$cat"
  if [ ! -d "$FOLDER" ]; then
    mkdir -p "$FOLDER"
    echo "Created folder: $FOLDER"
  else
    echo "Folder already exists: $FOLDER"
  fi
done

echo "All required folders have been created in:"
echo "$TARGET_BASE"
```

---

## Step-by-Step Guide

### 1. **Save Your PlugIns.xml**
   - Download your `PlugIns.xml` file to a known location, e.g., `~/Downloads/PlugIns.xml`.

### 2. **Save the Script**
   - Copy the above script into a text editor and save it as `create_logic_plugin_folders.sh` in your home directory or another convenient location.

### 3. **Make the Script Executable**
   ```bash
   chmod +x ~/create_logic_plugin_folders.sh
   ```

### 4. **Install xmllint (if needed)**
   - `xmllint` is included on macOS by default. If you get a "command not found" error, install it via [Homebrew](https://brew.sh/):
   ```bash
   brew install libxml2
   export PATH="/usr/local/opt/libxml2/bin:$PATH"
   ```

### 5. **Run the Script**
   ```bash
   ~/create_logic_plugin_folders.sh
   ```

   - The script will read `PlugIns.xml`, extract all unique `mainCategory_1` fields that are not "-", and create a folder for each in your Logic Pro Plug-In Settings directory.

### 6. **(Optional) Adjust Paths**
   - If your XML or Plug-In Settings folder is in a different location, edit the `XML_PATH` and `TARGET_BASE` variables near the top of the script.

---

**Tip:**  
- This only creates folders matching your XML’s `mainCategory_1` fields. If you want to create nested folders (e.g., by manufacturer or other tags), the script can be modified accordingly.
- Logic Pro's Plugin Manager does not use the file system for folder structure directly, but this approach is useful for custom organization, backups, or other DAWs that honor these directories.

---