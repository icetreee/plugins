#!/usr/bin/env python3
import os
import plistlib
from datetime import datetime
import shutil
from pathlib import Path

# Configuration
LOGIC_PLUGINS_PATH = os.path.expanduser("~/Music/Audio Music Apps/Plug-In Settings/Logic")
BACKUP_DIR = os.path.expanduser("~/Music/Audio Music Apps/Plug-In Settings/Logic_Backup")

def create_backup():
    """Create a backup of the current plugin folders"""
    if os.path.exists(LOGIC_PLUGINS_PATH):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = f"{BACKUP_DIR}_{timestamp}"
        shutil.copytree(LOGIC_PLUGINS_PATH, backup_path)
        print(f"Backup created at: {backup_path}")

def parse_plugin_categories(xml_path):
    """Parse the plugin XML file and extract category information"""
    with open(xml_path, 'rb') as file:
        plugins_data = plistlib.load(file)

    categories = {}
    for plugin in plugins_data:
        # Get main categories
        main_cats = [
            plugin.get(f'mainCategory_{i}', '-') 
            for i in range(1, 4)
            if plugin.get(f'mainCategory_{i}', '-') != '-'
        ]
        
        # Get sub categories
        sub_cats = [
            plugin.get(f'category_{i}', '-') 
            for i in range(1, 4)
            if plugin.get(f'category_{i}', '-') != '-'
        ]
        
        plugin_name = plugin.get('name', 'Unknown')
        
        # Process main categories and their subcategories
        for main_cat in main_cats:
            if main_cat not in categories:
                categories[main_cat] = set()
            
            # Add subcategories
            for sub_cat in sub_cats:
                if sub_cat != '-':
                    categories[main_cat].add(sub_cat)
    
    return categories

def create_folder_structure(categories):
    """Create the folder structure based on parsed categories"""
    os.makedirs(LOGIC_PLUGINS_PATH, exist_ok=True)
    
    for main_cat, sub_cats in categories.items():
        # Create main category folder
        main_path = os.path.join(LOGIC_PLUGINS_PATH, main_cat)
        os.makedirs(main_path, exist_ok=True)
        
        # Create subcategory folders
        for sub_cat in sub_cats:
            sub_path = os.path.join(main_path, sub_cat)
            os.makedirs(sub_path, exist_ok=True)

def main():
    # Path to the XML file
    xml_path = "PlugIns.xml"
    
    # Create backup first
    create_backup()
    
    try:
        # Parse categories from XML
        print("Parsing plugin categories...")
        categories = parse_plugin_categories(xml_path)
        
        # Create folder structure
        print("Creating folder structure...")
        create_folder_structure(categories)
        
        print("\nFolder structure created successfully!")
        print(f"Location: {LOGIC_PLUGINS_PATH}")
        
        # Print summary
        print("\nCreated folders:")
        for main_cat, sub_cats in categories.items():
            print(f"\n{main_cat}/")
            for sub_cat in sorted(sub_cats):
                print(f"  └── {sub_cat}/")
                
    except Exception as e:
        print(f"Error: {str(e)}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())