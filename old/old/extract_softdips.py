# ./includes/extract_soft_dips.py
# -*- coding: utf-8 -*-
# a library to extract neogeo soft dips from a rom file (program rom files usually end with a .p1 file extension).
# country should be JP, US or EU. Else the lib takes by default EU.
# usage: 
# - game_dips = GameSoftDips('./rom/romname.zip', "JP")
# - if game_dips.loaded:
#       game_dips.print_settings()
#       game_dips.game_name

import yaml, struct, zipfile, os, tempfile
from typing import List, Union
from PIL import Image, ImageDraw, ImageFont
from slugify import slugify

class SpecialSetting:
    def __init__(self, description: str, value: Union[str, int]):
        self.description = description
        self.value = value

class SimpleSetting:
    def __init__(self, description: str, default_value: int, value_descriptions: List[str]):
        self.description = description
        self.default_value = default_value
        self.value_descriptions = value_descriptions

class GameSoftDips:
    def __init__(self, rom_name: str, country = 'EU', file_path: str = None):
        self.loaded = False
        self.rom_name = rom_name
        self.game_name = ''
        self.country = country
        self.special_settings = []
        self.simple_settings = []
        
        # Check if settings exist in the YAML file
        self.dips_yaml = 'dips.yaml'
        settings = self.load_settings_from_yaml(filepath=self.dips_yaml, country= country, romname=self.rom_name)
        
        if settings and self.loaded:
            self.process_yaml_settings(settings)
        elif file_path:
            self.process_file(file_path, country)
        else:
            print("No settings found in the YAML and no file path provided to load from ROM.")

    def byteswap_2(self, data):
        return b''.join([data[i:i+2][::-1] for i in range(0, len(data), 2)])

    def process_file(self, file_path: str, country: str):
        # Check for settings in dips.yaml before loading from the file
        if self.load_settings_from_yaml(filepath=file_path, country=country, romname=self.rom_name):
            self.loaded = True
            return

        # If not found in YAML, proceed with the original method
        try:
            open(file_path, 'rb')
        except FileNotFoundError:
            self.loaded = False
            return -1


        file_extension = os.path.splitext(file_path)[1]
        if file_extension == ".zip":
            self.process_zip_file(file_path, country)
        else:
            self.loaded = False
            print(f"Softdips: unsupported file format: {file_extension}")

    def load_settings_from_yaml(self, filepath, romname, country, default_settings=None):
        try:
            with open(filepath, 'r') as file:
                data = yaml.safe_load(file) or {}

            # Get the top-level key (romname in your case)
            romname_settings = data.get(romname, {})

            # Extract country-specific settings
            country_settings = romname_settings.get(country, {})

            # Check if the settings for the specific country have been loaded
            self.loaded = bool(country_settings)

            # If there are country-specific settings, use them
            if self.loaded:
                self.settings = country_settings
            else:
                # If default settings were provided, use them
                if default_settings is not None:
                    print(f"No settings found for {country}. Using provided default settings.")
                    self.settings = default_settings
                else:
                    # If no defaults, inform the user and keep settings empty or use global defaults
                    print(f"No settings found for {romname}/{country} in YAML.")

        except FileNotFoundError:
            print(f"The file {filepath} does not exist. Using default settings if provided.")
            if default_settings:
                self.settings = default_settings
                self.loaded = True
        except yaml.YAMLError as e:
            print(f"Error parsing YAML file: {e}")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")


    def process_zip_file(self, file_path: str, country: str):
        with zipfile.ZipFile(file_path, 'r') as zip_ref:
            for file_info in zip_ref.infolist():
                if file_info.filename.endswith('.p1'):
                    with zip_ref.open(file_info.filename) as file:
                        temp_dir = tempfile.mkdtemp()
                        # Extract only the base filename without directories
                        base_filename = os.path.basename(file_info.filename)
                        temp_file_path = os.path.join(temp_dir, base_filename)
                        with open(temp_file_path, 'wb') as temp_file:
                            temp_file.write(file.read())
                        self.load_from_file(temp_file_path, country)
                        os.remove(temp_file_path)  # Delete the temporary file
                        os.rmdir(temp_dir)  # Delete the temporary directory
                    break
            else:
                self.loaded = False
                print (f'Softdips: No .p1 file found in the zip archive ({file_path}).')
        
    def process_yaml_settings(self, settings):
        # Retrieve settings for the specific country
        country_settings = settings.get(self.country, None)
        if country_settings is not None:
            self.loaded = True
            self.game_name = country_settings.get('game_name', '')
            self.special_settings = [SpecialSetting(s['description'], s['value']) for s in country_settings.get('special_settings', [])]
            self.simple_settings = [SimpleSetting(s['description'], s['default_value'], s['value_descriptions']) for s in country_settings.get('simple_settings', [])]
        else:
            # If settings for the current country are not found, check if there are settings for any country
            if settings:
                # Here, we could decide to take the first available country settings or a specific other country's settings
                # For now, let's assume we just take the first available country's settings
                first_available_country = next(iter(settings))
                self.process_yaml_settings(settings[first_available_country])
            else:
                # No settings for any country are available
                self.loaded = False


        
    def update_yaml_settings(self):
        # Create the settings structure with country code as a key
        settings = {
            self.country: {
                'game_name': self.game_name,
                'special_settings': [{'description': s.description, 'value': s.value} for s in self.special_settings],
                'simple_settings': [{'description': s.description, 'default_value': s.default_value, 'value_descriptions': s.value_descriptions} for s in self.simple_settings]
            }
        }
        
        # Load existing YAML data
        existing_data = self.load_settings_from_yaml(country=self.country, filepath=self.dips_yaml, romname= self.rom_name) or {}
        
        # Check if there's already an entry for this rom_name and merge the settings
        if self.rom_name in existing_data:
            existing_data[self.rom_name].update(settings)
        else:
            existing_data[self.rom_name] = settings
        
        # Write the updated data back to the YAML file
        with open(self.dips_yaml, 'w') as yaml_file:
            yaml.safe_dump(existing_data, yaml_file, default_flow_style=False)



    def load_from_file(self, file_path: str, country: str):
        data = self.read_binary_file(file_path)
        index = self.find_neogeo_string(data)
        if index == -1:
            self.loaded = False
            return -1
        else:
            # NEO GEO string has been found, lets see where the softdips are (differs for each rom)
            dip_pointer = self.get_dip_pointer(data, country)
            if dip_pointer > len(data): #pointer out of range?
                self.loaded = False
            else:
                self.loaded = True
                self.game_name = self.get_game_name(data, dip_pointer)        
                self.get_game_settings(data, dip_pointer)

        if self.loaded:
            self.update_yaml_settings()

        
    def read_binary_file(self, filename):
        with open(filename, 'rb') as f:
            return f.read()

    def find_neogeo_string(self, data):
        neo_geo_byteswapped = b'EN-OEG'
        index = data.find(neo_geo_byteswapped)
        if index == 256: # 256 (hex: 0x100) is where the string should be found
            return index
        else:
            return -1

    def get_dip_pointer(self, data, country: str):
        # default value is JP
        dip_pointer_bytes = data[0x116:0x116 + 4]

        if country == "JP": dip_pointer_bytes = data[0x116:0x116 + 4]
        if country == "US": dip_pointer_bytes = data[0x11A:0x11A + 4]
        if country == "EU": dip_pointer_bytes = data[0x11E:0x11E + 4]

        byteswapped = dip_pointer_bytes[2:4] + dip_pointer_bytes[0:2]
        dip_pointer = struct.unpack('<L', byteswapped)[0]
        #print(f'Pointer to DIP settings: {hex(dip_pointer)}')
        return dip_pointer

    def get_game_name(self, data, dip_pointer):
        game_name_offset = dip_pointer
        game_name_bytes = data[game_name_offset:game_name_offset + 16]
        byteswapped = self.byteswap_2(game_name_bytes)
        game_name = byteswapped.decode('utf-8', errors='ignore').strip()
        return game_name

    def get_game_settings(self, data, dip_pointer):
        # Extract special settings list
        special_settings_bytes = data[dip_pointer + 0x10:dip_pointer + 0x10 + 8]
        byteswapped_special_settings = self.byteswap_2(special_settings_bytes)
        
        # Description offset for special settings (common for all)
        description_index = dip_pointer + 0x20  # Initialize description_index
        
        # Process time settings (first two entries of special settings)
        for i in range(0, 4, 2):
            time_setting_bytes = byteswapped_special_settings[i:i+2]
            if time_setting_bytes != b'\xff\xff':
                # Fetch the description
                description_bytes = data[description_index:description_index+12]
                description = self.byteswap_2(description_bytes).decode('utf-8', errors='ignore').strip()
                description_index += 12  # Move to next description
                minutes = int(f'{time_setting_bytes[0]:x}')
                seconds = int(f'{time_setting_bytes[1]:x}')
                time_value = f'{minutes:02d}:{seconds:02d}'
                self.special_settings.append(SpecialSetting(description, time_value))
    
        # Process count settings (last two entries of special settings)
        for i in range(4, 6):
            count_setting_byte = byteswapped_special_settings[i]
            if count_setting_byte != 0xff:
                # Obtain the description from the settings_strings table
                description_bytes = data[description_index:description_index+12]
                description = self.byteswap_2(description_bytes).decode('utf-8', errors='ignore').strip()
                description_index += 12  # Move to next description
                    
                # Determine the value representation
                count_value = "INFINITE" if count_setting_byte == 100 else \
                            "WITHOUT" if count_setting_byte == 0 else \
                            f'{count_setting_byte}' if count_setting_byte < 100 else \
                            count_setting_byte  # Handle any other unexpected values
                # Append the special setting
                self.special_settings.append(SpecialSetting(description, count_value))

        # simple settings
        simple_settings_bytes = data[dip_pointer + 0x16:dip_pointer + 0x16 + 10]
        simple_settings_bytes = self.byteswap_2(simple_settings_bytes)

        for i in range(10):
            setting_byte = simple_settings_bytes[i]
            if setting_byte != 0x00:
                # Fetch main description
                description_bytes = data[description_index:description_index+12]
                description = self.byteswap_2(description_bytes).decode('utf-8', errors='ignore').strip()
                description_index += 12  # Move to next description

                # Fetch value descriptions
                value_descriptions = []
                num_value_descriptions = setting_byte & 0x0F  # Lower 4 bits represent number of value descriptions
                for j in range(num_value_descriptions):
                    value_description_bytes = data[description_index:description_index+12]
                    value_description = self.byteswap_2(value_description_bytes).decode('utf-8', errors='ignore').strip()
                    value_descriptions.append(value_description)
                    description_index += 12  # Move to next description

                default_value = setting_byte >> 4  # Upper 4 bits represent default value
                self.simple_settings.append(SimpleSetting(description, default_value, value_descriptions))
   
if __name__ == '__main__':
    # Usage example
    game_dips = GameSoftDips('mslug2', "EU", './rom/mslug2.zip')
    #game_dips = GameSoftDips('abyssalinfants', "EU", './rom/abyssalinfants.zip')
    if game_dips.loaded:
        game_dips.print_settings()
        image_filename = game_dips.generate_image('./img-cache/soft-dips')
        print(f'softdips saved to {image_filename}')
    else:
        print('soft dips not found')
