#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import os
import sys
import logging
from datetime import datetime
from pathlib import Path
from typing import Set, Dict, List

class PluginOrganizerError(Exception):
    """Custom exception for plugin organizer errors"""
    pass

class LogicPluginOrganizer:
    def __init__(self, xml_path: str = None):
        """Initialize the plugin organizer with optional custom XML path"""
        self.xml_path = xml_path or os.path.expanduser("~/Library/Preferences/com.apple.logic.pro.plist")
        self.plugin_dir = os.path.expanduser("~/Library/Audio/Plug-Ins/Components")
        self.categories: Dict[str, Set[str]] = {}
        self.setup_logging()

    def setup_logging(self):
        """Configure logging with both file and console output"""
        log_dir = os.path.expanduser("~/Library/Logs/LogicPluginOrganizer")
        os.makedirs(log_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = os.path.join(log_dir, f"plugin_organizer_{timestamp}.log")
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def parse_xml(self):
        """Parse the XML file and extract category information"""
        try:
            tree = ET.parse(self.xml_path)
            root = tree.getroot()
            
            for plugin in root.findall(".//dict"):
                self._extract_categories(plugin)
                
        except ET.ParseError as e:
            raise PluginOrganizerError(f"XML parsing error: {e}")
        except Exception as e:
            raise PluginOrganizerError(f"Error processing XML file: {e}")

    def _extract_categories(self, plugin_dict):
        """Extract main and sub categories from a plugin dictionary"""
        categories = {
            'mainCategory_1': None,
            'mainCategory_2': None,
            'mainCategory_3': None,
            'subCategory_1': None,
            'subCategory_2': None,
            'subCategory_3': None
        }
        
        current_key = None
        for elem in plugin_dict:
            if elem.tag == 'key':
                current_key = elem.text
            elif current_key in categories:
                if elem.text != '-' and elem.text:
                    if current_key.startswith('main'):
                        main_cat = elem.text
                        if main_cat not in self.categories:
                            self.categories[main_cat] = set()
                    elif current_key.startswith('sub'):
                        main_index = int(current_key[-1])
                        main_cat_key = f'mainCategory_{main_index}'
                        main_cat = categories.get(main_cat_key)
                        if main_cat and elem.text != '-':
                            self.categories[main_cat].add(elem.text)

    def create_folder_structure(self):
        """Create the folder structure based on extracted categories"""
        try:
            os.makedirs(self.plugin_dir, exist_ok=True)
            
            for main_cat, sub_cats in self.categories.items():
                main_path = os.path.join(self.plugin_dir, self._sanitize_name(main_cat))
                self._create_folder(main_path)
                
                for sub_cat in sub_cats:
                    sub_path = os.path.join(main_path, self._sanitize_name(sub_cat))
                    self._create_folder(sub_path)
                    
        except Exception as e:
            raise PluginOrganizerError(f"Error creating folder structure: {e}")

    def _create_folder(self, path: str):
        """Create a folder with proper error handling and logging"""
        try:
            if not os.path.exists(path):
                os.makedirs(path)
                self.logger.info(f"Created folder: {path}")
            else:
                self.logger.debug(f"Folder already exists: {path}")
        except PermissionError:
            self.logger.error(f"Permission denied creating folder: {path}")
        except Exception as e:
            self.logger.error(f"Error creating folder {path}: {e}")

    @staticmethod
    def _sanitize_name(name: str) -> str:
        """Sanitize folder names for filesystem compatibility"""
        # Replace problematic characters while preserving spaces
        invalid_chars = '<>:"/\\|?*'
        return ''.join(c if c not in invalid_chars else '_' for c in name).strip()

    def validate_permissions(self) -> bool:
        """Validate write permissions for plugin directory"""
        try:
            test_path = os.path.join(self.plugin_dir, '.test_write_permission')
            with open(test_path, 'w') as f:
                f.write('')
            os.remove(test_path)
            return True
        except Exception as e:
            self.logger.error(f"Permission validation failed: {e}")
            return False

    def run(self):
        """Main execution method"""
        try:
            self.logger.info("Starting plugin organization process...")
            
            if not self.validate_permissions():
                raise PluginOrganizerError("Insufficient permissions for plugin directory")
            
            self.logger.info("Parsing XML file...")
            self.parse_xml()
            
            self.logger.info("Creating folder structure...")
            self.create_folder_structure()
            
            self.logger.info("Plugin organization completed successfully")
            
        except PluginOrganizerError as e:
            self.logger.error(f"Plugin organization failed: {e}")
            sys.exit(1)

def main():
    """Main entry point with command line argument handling"""
    try:
        xml_path = sys.argv[1] if len(sys.argv) > 1 else None
        organizer = LogicPluginOrganizer(xml_path)
        organizer.run()
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()