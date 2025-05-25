#!/usr/bin/env python3
"""
Logic Pro Plugin Organizer
Automatically creates custom folders/categories in Logic Pro's plugin manager
by modifying the PlugIns.xml PLIST file.

Author: Based on architectural plan from DeepSeek-R1
Usage: python3 logic_plugin_organizer.py [options]
"""

import plistlib
import json
import os
import sys
import argparse
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

class LogicPluginOrganizer:
    def __init__(self, plist_path: str = None):
        """Initialize the organizer with the path to PlugIns.xml"""
        if plist_path is None:
            self.plist_path = os.path.expanduser("~/Music/Audio Music Apps/Plug-In Settings/PlugIns.xml")
        else:
            self.plist_path = os.path.expanduser(plist_path)
        
        self.plist_data = None
        self.backup_path = None
        
    def create_backup(self) -> str:
        """Create a timestamped backup of the original PlugIns.xml file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_filename = f"PlugIns_backup_{timestamp}.xml"
        self.backup_path = os.path.join(os.path.dirname(self.plist_path), backup_filename)
        
        try:
            shutil.copy2(self.plist_path, self.backup_path)
            print(f"✓ Backup created: {self.backup_path}")
            return self.backup_path
        except Exception as e:
            raise Exception(f"Failed to create backup: {e}")
    
    def restore_backup(self) -> None:
        """Restore from backup if something goes wrong"""
        if self.backup_path and os.path.exists(self.backup_path):
            try:
                shutil.copy2(self.backup_path, self.plist_path)
                print(f"✓ Restored from backup: {self.backup_path}")
            except Exception as e:
                print(f"✗ Failed to restore backup: {e}")
    
    def validate_plist(self) -> bool:
        """Validate the PLIST file using plutil"""
        try:
            result = subprocess.run(['plutil', '-lint', self.plist_path], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                print("✓ PLIST validation passed")
                return True
            else:
                print(f"✗ PLIST validation failed: {result.stderr}")
                return False
        except FileNotFoundError:
            print("⚠ plutil not found, skipping validation")
            return True  # Assume valid if plutil is not available
        except Exception as e:
            print(f"✗ Error during validation: {e}")
            return False
    
    def load_plist(self) -> None:
        """Load the PlugIns.xml PLIST file"""
        if not os.path.exists(self.plist_path):
            raise FileNotFoundError(f"PlugIns.xml not found at: {self.plist_path}")
        
        try:
            with open(self.plist_path, 'rb') as f:
                self.plist_data = plistlib.load(f)
            print(f"✓ Loaded PLIST with {len(self.plist_data)} plugins")
        except Exception as e:
            raise Exception(f"Failed to load PLIST: {e}")
    
    def save_plist(self) -> None:
        """Save the modified PLIST file"""
        try:
            with open(self.plist_path, 'wb') as f:
                plistlib.dump(self.plist_data, f)
            print("✓ PLIST saved successfully")
        except Exception as e:
            raise Exception(f"Failed to save PLIST: {e}")
    
    def find_plugin_by_unique_name(self, unique_name: str) -> Optional[Dict]:
        """Find a plugin by its uniqueName field"""
        if not self.plist_data:
            return None
            
        for plugin in self.plist_data:
            if isinstance(plugin, dict) and plugin.get('uniqueName') == unique_name:
                return plugin
        return None
    
    def find_plugin_by_name_manufacturer(self, name: str, manufacturer: str) -> Optional[Dict]:
        """Find a plugin by name and manufacturer (fallback method)"""
        if not self.plist_data:
            return None
            
        for plugin in self.plist_data:
            if (isinstance(plugin, dict) and 
                plugin.get('name') == name and 
                plugin.get('manufacturer') == manufacturer):
                return plugin
        return None
    
    def clear_existing_custom_categories(self, plugin: Dict) -> None:
        """Clear existing custom categories from a plugin"""
        for i in range(1, 4):  # category_1, category_2, category_3
            category_key = f"category_{i}"
            custom_key = f"category_{i}isCustom"
            
            # Only clear if it's marked as custom
            if plugin.get(custom_key) is True:
                plugin.pop(category_key, None)
                plugin.pop(custom_key, None)
    
    def set_plugin_categories(self, plugin: Dict, categories: List[str]) -> None:
        """Set custom categories for a plugin"""
        # Clear existing custom categories first
        self.clear_existing_custom_categories(plugin)
        
        # Set new categories (max 3 levels)
        for i, category in enumerate(categories[:3], 1):
            plugin[f"category_{i}"] = category
            plugin[f"category_{i}isCustom"] = True
        
        # Clear any remaining higher-level categories if switching to fewer levels
        for i in range(len(categories) + 1, 4):
            category_key = f"category_{i}"
            custom_key = f"category_{i}isCustom"
            plugin.pop(category_key, None)
            plugin.pop(custom_key, None)
    
    def apply_configuration(self, config: Dict) -> None:
        """Apply the folder configuration to plugins"""
        if not self.plist_data:
            raise Exception("PLIST data not loaded")
        
        total_plugins_processed = 0
        
        for folder_config in config.get('folders', []):
            categories = folder_config.get('categories', [])
            plugins = folder_config.get('plugins', [])
            
            if not categories:
                print(f"⚠ Skipping folder config with no categories: {folder_config}")
                continue
            
            print(f"\n📁 Processing folder: {' > '.join(categories)}")
            
            for plugin_identifier in plugins:
                # Try to find plugin by uniqueName first
                plugin = self.find_plugin_by_unique_name(plugin_identifier)
                
                # If not found and identifier contains underscore, try name/manufacturer split
                if not plugin and '_' in plugin_identifier:
                    parts = plugin_identifier.split('_', 1)
                    if len(parts) == 2:
                        manufacturer, name = parts
                        plugin = self.find_plugin_by_name_manufacturer(name, manufacturer)
                
                if plugin:
                    old_categories = []
                    for i in range(1, 4):
                        if f"category_{i}" in plugin:
                            old_categories.append(plugin[f"category_{i}"])
                    
                    self.set_plugin_categories(plugin, categories)
                    
                    old_path = " > ".join(old_categories) if old_categories else "(none)"
                    new_path = " > ".join(categories)
                    
                    plugin_name = plugin.get('name', 'Unknown')
                    manufacturer = plugin.get('manufacturer', 'Unknown')
                    
                    print(f"  ✓ {manufacturer} - {plugin_name}")
                    print(f"    {old_path} → {new_path}")
                    
                    total_plugins_processed += 1
                else:
                    print(f"  ✗ Plugin not found: {plugin_identifier}")
        
        print(f"\n✓ Total plugins processed: {total_plugins_processed}")
    
    def list_all_plugins(self) -> None:
        """List all plugins with their current categories (for debugging)"""
        if not self.plist_data:
            self.load_plist()
        
        print("\n📋 All plugins in PlugIns.xml:")
        print("-" * 80)
        
        for i, plugin in enumerate(self.plist_data):
            if isinstance(plugin, dict):
                name = plugin.get('name', 'Unknown')
                manufacturer = plugin.get('manufacturer', 'Unknown')
                unique_name = plugin.get('uniqueName', 'Unknown')
                
                # Get current categories
                categories = []
                for j in range(1, 4):
                    if f"category_{j}" in plugin:
                        cat = plugin[f"category_{j}"]
                        is_custom = plugin.get(f"category_{j}isCustom", False)
                        categories.append(f"{cat}{'*' if is_custom else ''}")
                
                category_path = " > ".join(categories) if categories else "(none)"
                
                print(f"{i+1:3d}. {manufacturer} - {name}")
                print(f"     UniqueID: {unique_name}")
                print(f"     Categories: {category_path}")
                print()

def load_config_from_file(config_path: str) -> Dict:
    """Load configuration from JSON file"""
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        print(f"✓ Loaded configuration from: {config_path}")
        return config
    except Exception as e:
        raise Exception(f"Failed to load configuration: {e}")

def create_sample_config(output_path: str) -> None:
    """Create a sample configuration file"""
    sample_config = {
        "folders": [
            {
                "plugins": [
                    "2Rule_2RuleSynth_aumu_none",
                    "Logic_Alchemy_aumu_none"
                ],
                "categories": ["My Synths", "Favorites"]
            },
            {
                "plugins": [
                    "FabFilter_Pro-Q 3_auaa_none"
                ],
                "categories": ["Best EQs"]
            },
            {
                "plugins": [
                    "Logic_Adaptive Limiter_aufx_none",
                    "Logic_Multipressor_aufx_none"
                ],
                "categories": ["Logic Dynamics"]
            }
        ]
    }
    
    try:
        with open(output_path, 'w') as f:
            json.dump(sample_config, f, indent=2)
        print(f"✓ Sample configuration created: {output_path}")
        print("\nEdit this file to specify your desired plugin organization.")
        print("You can find plugin identifiers using the --list-plugins option.")
    except Exception as e:
        print(f"✗ Failed to create sample configuration: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Organize Logic Pro plugins into custom folders",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create a sample configuration file
  python3 logic_plugin_organizer.py --create-config my_config.json
  
  # List all plugins to find their identifiers
  python3 logic_plugin_organizer.py --list-plugins
  
  # Apply organization from configuration file
  python3 logic_plugin_organizer.py --config my_config.json
  
  # Dry run to preview changes
  python3 logic_plugin_organizer.py --config my_config.json --dry-run
  
  # Use custom PlugIns.xml path
  python3 logic_plugin_organizer.py --config my_config.json --plist-path /path/to/PlugIns.xml
        """
    )
    
    parser.add_argument('--config', '-c', 
                       help='Path to JSON configuration file')
    parser.add_argument('--plist-path', '-p',
                       help='Path to PlugIns.xml file (default: ~/Music/Audio Music Apps/Plug-In Settings/PlugIns.xml)')
    parser.add_argument('--create-config', 
                       help='Create a sample configuration file at the specified path')
    parser.add_argument('--list-plugins', action='store_true',
                       help='List all plugins and their current categories')
    parser.add_argument('--dry-run', action='store_true',
                       help='Preview changes without modifying the file')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose output')
    
    args = parser.parse_args()
    
    # Create sample configuration
    if args.create_config:
        create_sample_config(args.create_config)
        return
    
    # Initialize organizer
    try:
        organizer = LogicPluginOrganizer(args.plist_path)
        organizer.load_plist()
    except Exception as e:
        print(f"✗ Error initializing: {e}")
        sys.exit(1)
    
    # List plugins
    if args.list_plugins:
        organizer.list_all_plugins()
        return
    
    # Apply configuration
    if args.config:
        try:
            config = load_config_from_file(args.config)
            
            if args.dry_run:
                print("🔍 DRY RUN MODE - No changes will be made")
                print("=" * 50)
            
            if not args.dry_run:
                # Create backup before making changes
                organizer.create_backup()
            
            # Apply the configuration
            organizer.apply_configuration(config)
            
            if not args.dry_run:
                # Save changes and validate
                organizer.save_plist()
                
                if not organizer.validate_plist():
                    print("✗ PLIST validation failed, restoring backup...")
                    organizer.restore_backup()
                    sys.exit(1)
                
                print("\n✅ Plugin organization completed successfully!")
                print("Restart Logic Pro to see the changes.")
            else:
                print("\n🔍 Dry run completed. Use --config without --dry-run to apply changes.")
                
        except Exception as e:
            print(f"✗ Error during processing: {e}")
            if not args.dry_run:
                organizer.restore_backup()
            sys.exit(1)
    else:
        print("No action specified. Use --help for usage information.")
        print("Start with --create-config to create a sample configuration file.")

if __name__ == "__main__":
    main()
