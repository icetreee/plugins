#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import os
import argparse
import logging

def parse_xml(xml_file):
    """Parses the XML file and extracts plugin information."""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        plugins = []
        for plugin_dict in root.findall('./dict'):
            plugin_data = {}
            for element in plugin_dict:
                if element.tag in ['mainCategory_1', 'mainCategory_2', 'mainCategory_3',
                                   'subCategory_1', 'subCategory_2', 'subCategory_3']:
                    plugin_data[element.tag] = element.text
            plugins.append(plugin_data)
        return plugins
    except ET.ParseError as e:
        logging.error(f"XML Parsing Error: {e}")
        return None
    except FileNotFoundError:
        logging.error(f"File not found: {xml_file}")
        return None
    except Exception as e:
        logging.error(f"An unexpected error occurred during XML parsing: {e}")
        return None

def create_directories(plugins, base_dir):
    """Creates the directories based on the plugin information."""
    created_count = 0
    skipped_count = 0
    for plugin in plugins:
        for i in range(1, 4):
            main_category = plugin.get(f'mainCategory_{i}', '-')
            sub_category = plugin.get(f'subCategory_{i}', '-')

            if main_category == '-':
                continue

            dir_path = os.path.join(base_dir, main_category)
            if sub_category != '-':
                dir_path = os.path.join(dir_path, sub_category)

            try:
                os.makedirs(dir_path, exist_ok=True)
                if os.path.exists(dir_path):
                    logging.info(f"Directory skipped (already exists): {dir_path}")
                    skipped_count += 1
                else:
                    logging.info(f"Directory created: {dir_path}")
                    created_count += 1
            except OSError as e:
                logging.error(f"Error creating directory {dir_path}: {e}")
    return created_count, skipped_count

def main():
    """Main function to parse arguments and execute the script."""
    parser = argparse.ArgumentParser(description="Create plugin folders based on PlugIns.xml.")
    parser.add_argument("--xml_file", help="Path to the PlugIns.xml file.",
                        default=os.path.expanduser("~/Library/Audio/Plug-Ins/Components/PlugIns.xml"))
    parser.add_argument("--base_dir", help="Base directory for plugin folders.",
                        default=os.path.expanduser("~/Library/Audio/Plug-Ins/Components"))
    parser.add_argument("--log_file", help="Path to the log file.",
                        default="plugin_folder_creation.log")

    args = parser.parse_args()

    # Configure logging
    logging.basicConfig(filename=args.log_file, level=logging.INFO,
                        format='%(asctime)s - %(levelname)s - %(message)s')

    logging.info("Starting plugin folder creation script.")

    plugins = parse_xml(args.xml_file)

    if plugins is None:
        logging.error("Failed to parse XML. Check the file and try again.")
        return

    created_count, skipped_count = create_directories(plugins, args.base_dir)

    logging.info(f"Script completed. Created {created_count} directories, skipped {skipped_count} directories.")

if __name__ == "__main__":
    main()