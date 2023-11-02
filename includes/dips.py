# ./includes/dips.yaml
import yaml, os, zipfile, tempfile, struct
from typing import Union, List
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

class SoftDipsSettings:
    def __init__(self, softdips_yaml_file, debugdips_yaml_file):
        self.yaml_file = softdips_yaml_file
        self.softdip_settings = self.load_yaml(softdips_yaml_file)
        self.debug_settings = self.load_yaml(debugdips_yaml_file)
        
    @staticmethod
    def load_yaml(softdips_yaml_file):
        with open(softdips_yaml_file, 'r') as file:
            return yaml.safe_load(file)

    def game_settings_found(self, game_code, region) -> bool:
        """
        Check if the game settings for a given game code and region are present.

        :param game_code: The game code as a string.
        :param region: The region as a string.
        :return: True if settings are present, False otherwise.
        """
        # This line checks if the game code exists in the settings dictionary and if the region also exists under that game code.
        return bool(self.softdip_settings.get(game_code, {}).get(region, {}))

    def get_game_name(self, game_code, region):
        return self.softdip_settings.get(game_code, {}).get(region, {}).get('game_name', "Unknown Game")

    def save_softdip_yaml(self):
        with open(self.yaml_file, 'w') as file:
            yaml.safe_dump(self.softdip_settings, file)

    def print_settings(self, game_code, region):
        game_settings = self.softdip_settings.get(game_code, {}).get(region, {})
        if not game_settings:
            print(f"No settings found for game {game_code} in {region} region.")
            return

        game_name = game_settings.get('game_name', 'Unknown')
        print()
        print(f'Game: {game_name} ({region})')
        print('Software DIPs Settings:')

        if 'special_settings' in game_settings:
            for setting in game_settings['special_settings']:
                print(f'- {setting["description"]}: {setting["value"]}')

        if 'simple_settings' in game_settings:
            for setting in game_settings['simple_settings']:
                print(f'- {setting["description"]}: ', end='')
                for i, value_description in enumerate(setting['value_descriptions'], start=1):
                    if i != 1: print(', ', end='')
                    print(value_description, end='')
                    if i == setting['default_value'] + 1: print(' (default)', end='')
                print('.')

    def generate_settings_image(self, path, game_code, region):
        game_settings = self.softdip_settings.get(game_code, {}).get(region, {})
        if not game_settings:
            print(f"No settings found for game {game_code} in {region} region.")
            return

        game_name = game_settings.get('game_name', 'Unknown')

        SIZEH = 35
        FONTSIZE = 40
        TITLECOLOR = (255, 100, 100)
        TXTCOLOR = (255, 255, 255)
        BGCOLOR = (53, 68, 81)
        LMARGIN = 15
        HMARGIN = 15
        IMGWIDTH = 1200

        settings_count = sum(1 for _ in self.get_game_settings_line_by_line(game_code, region))

        # image background
        im_height = 2 * HMARGIN + SIZEH * (settings_count + 3)
        im = Image.new("RGBA", (IMGWIDTH, im_height), BGCOLOR)
        draw = ImageDraw.Draw(im)
        draw.rounded_rectangle([3, 3, IMGWIDTH - 4, im_height - 3], radius=3, fill=None, outline=TXTCOLOR, width=1)

        # image title
        ARCADE_FONT = './fonts/AnonymousPro-Regular-arcade-controls.ttf'
        font = ImageFont.truetype(ARCADE_FONT, FONTSIZE)
        title = f'{game_name} game settings ("soft DIP switches")'
        draw.text((LMARGIN, HMARGIN), title, fill=TITLECOLOR, font=font, align='left')

        # Print each setting
        y = HMARGIN + SIZEH  # Initialize y-coordinate for text
        for setting in self.get_game_settings_line_by_line(game_code, region):
            y += SIZEH  # Move down for next line
            draw.text((LMARGIN, y), setting, fill=TXTCOLOR, font=font, align='left')
            
        # save the image on disk
        filename = path + '/dips-' + region + '-' + slugify(game_code) + '.png' 
        im.save(filename)
        return filename

    def get_game_settings_line_by_line(self, game_code, region):
        MAX_CHARS_PER_LINE = 48
        INDENT = '               '
        game_settings = self.softdip_settings.get(game_code, {}).get(region, {})

        if not game_settings:
            print(f"No settings found for game {game_code} in {region} region.")
            return

        # If your new settings have a different structure, you will need to adjust the accessors accordingly
        if 'special_settings' in game_settings:
            for setting in game_settings['special_settings']:
                description = setting['description']
                value = setting['value']
                line = f'{description}' + INDENT[0:14-len(description)] + f'{value}'
                yield line

        if 'simple_settings' in game_settings:
            for setting in game_settings['simple_settings']:
                description = setting['description']
                value_text = f'{description}' + INDENT[0:14-len(description)]
                for i, value_description in enumerate(setting['value_descriptions'], start=1):
                    if i != 1: value_text += ', '
                    # Break line if it exceeds MAX_CHARS_PER_LINE
                    if len(value_text) + len(value_description) + (2 if i != 1 else 0) > MAX_CHARS_PER_LINE:
                        yield value_text
                        value_text = INDENT
                    value_text += f'{value_description}'
                    if i == setting['default_value'] + 1:
                        value_text += '*'
                yield value_text


    def neogeo_rom_byteswap_2(self, data):
        return b''.join([data[i:i+2][::-1] for i in range(0, len(data), 2)])

    def set_game_settings(self, game_code, region, new_settings):
        """
        Set the game settings for a specific game code and region.
        If the game code does not exist, it will be created.

        :param game_code: The game code as a string.
        :param region: The region as a string.
        :param new_settings: A dictionary containing 'game_name', 'simple_settings', and 'special_settings'.
        """
        if 'game_name' not in new_settings:
            print("New settings must include 'game_name'.")
            return

        if game_code not in self.softdip_settings:
            self.softdip_settings[game_code] = {}

        # Set the new settings, replacing the old ones
        self.softdip_settings[game_code][region] = new_settings
        print(f"Settings for '{game_code}' in '{region}' have been updated.")

    def enrich_softdip_settings_from_rom(self, game_id, path, language):
        """
        Enrich the YAML settings file with data for a specific game and language.

        :param game_id: The game ID as a string.
        :param path: The path to the game file as a string.
        :param language: The language as a string.
        """
        game_settings = self._read_game_settings_from_rom(path, language)
        if game_settings is not None:
           self.set_game_settings(game_id, language, game_settings)
           self.save_softdip_yaml()
            
    def _read_game_settings_from_rom(self, rom_path: str, language: str):
        """
        Reads game settings from a given path and stores them in the appropriate format.
        """

        # Check if the file exists
        if not os.path.exists(rom_path):
            print(f"File does not exist: {rom_path}")
            return None
    
        # First, let's determine if the given file is a .zip
        file_extension = os.path.splitext(rom_path)[1]
        if file_extension == ".zip":
            # Process the zip file
            with zipfile.ZipFile(rom_path, 'r') as zip_ref:
                for file_info in zip_ref.infolist():
                    if file_info.filename.endswith('.p1'):
                        with zip_ref.open(file_info.filename) as file:
                            temp_dir = tempfile.mkdtemp()
                            base_filename = os.path.basename(file_info.filename)
                            temp_file_path = os.path.join(temp_dir, base_filename)
                            with open(temp_file_path, 'wb') as temp_file:
                                temp_file.write(file.read())
                            
                            # Now let's use the rest of the logic to load the settings from the extracted file
                            data = self.read_binary_file(temp_file_path)
                            index = self.check_neogeo_special_string_in_rom(data)
                            if index != -1:
                                dip_pointer = self.get_softdip_settings_pointer_from_rom(data, language)
                                if dip_pointer < len(data):
                                    game_name = self.get_rom_game_name(data, dip_pointer)
                                    special_settings, description_index = self.get_softdip_special_settings_from_rom(data, dip_pointer)
                                    simple_settings = self.get_softdip_simple_settings_from_rom(data, dip_pointer, description_index)
                                    return {
                                        'game_name': game_name,
                                        'special_settings': [s.__dict__ for s in special_settings],
                                        'simple_settings': [s.__dict__ for s in simple_settings]
                                    }
                                else:
                                    print("Pointer out of range while reading game settings.")
                                    return None
                            else:
                                print("NEO GEO string not found in the file.")
                                return None
                        
                        os.remove(temp_file_path)
                        os.rmdir(temp_dir)
                        break
                else:
                    print(f"No .p1 file found in the zip archive ({rom_path}).")
                    return None
        else:
            print(f"Unsupported file format: {file_extension}")
            return None

    def get_rom_game_name(self, data, dip_pointer):
        game_name_offset = dip_pointer
        game_name_bytes = data[game_name_offset:game_name_offset + 16]
        byteswapped = self.neogeo_rom_byteswap_2(game_name_bytes)
        game_name = byteswapped.decode('utf-8', errors='ignore').strip()
        return game_name

    def get_softdip_special_settings_from_rom(self, data, dip_pointer):
        special_settings = []
        special_settings_bytes = data[dip_pointer + 0x10:dip_pointer + 0x10 + 8]
        byteswapped_special_settings = self.neogeo_rom_byteswap_2(special_settings_bytes)
        
        # Description offset for special settings (common for all)
        description_index = dip_pointer + 0x20  # Initialize description_index
        
        # Process time settings (first two entries of special settings)
        for i in range(0, 4, 2):
            time_setting_bytes = byteswapped_special_settings[i:i+2]
            if time_setting_bytes != b'\xff\xff':
                description_bytes = data[description_index:description_index+12]
                description = self.neogeo_rom_byteswap_2(description_bytes).decode('utf-8', errors='ignore').strip()
                description_index += 12  # Move to next description
                minutes = int(f'{time_setting_bytes[0]:x}')
                seconds = int(f'{time_setting_bytes[1]:x}')
                time_value = f'{minutes:02d}:{seconds:02d}'
                special_settings.append(SpecialSetting(description, time_value))

        # Process count settings (last two entries of special settings)
        for i in range(4, 6):
            count_setting_byte = byteswapped_special_settings[i]
            if count_setting_byte != 0xff:
                description_bytes = data[description_index:description_index+12]
                description = self.neogeo_rom_byteswap_2(description_bytes).decode('utf-8', errors='ignore').strip()
                description_index += 12  # Move to next description
                    
                # Determine the value representation
                count_value = "INFINITE" if count_setting_byte == 100 else \
                            "WITHOUT" if count_setting_byte == 0 else \
                            f'{count_setting_byte}' if count_setting_byte < 100 else \
                            count_setting_byte
                special_settings.append(SpecialSetting(description, count_value))
        
        return special_settings, description_index

    def get_softdip_simple_settings_from_rom(self, data, dip_pointer, description_index):
        simple_settings = []
        simple_settings_bytes = data[dip_pointer + 0x16:dip_pointer + 0x16 + 10]
        simple_settings_bytes = self.neogeo_rom_byteswap_2(simple_settings_bytes)
        
        # description_index = dip_pointer + 0x20  # Assume this is the initial index for simple settings descriptions

        for i in range(10):
            setting_byte = simple_settings_bytes[i]
            if setting_byte != 0x00:
                description_bytes = data[description_index:description_index+12]
                description = self.neogeo_rom_byteswap_2(description_bytes).decode('utf-8', errors='ignore').strip()
                description_index += 12  # Move to next description

                value_descriptions = []
                num_value_descriptions = setting_byte & 0x0F  # Lower 4 bits for the number of value descriptions
                for j in range(num_value_descriptions):
                    value_description_bytes = data[description_index:description_index+12]
                    value_description = self.neogeo_rom_byteswap_2(value_description_bytes).decode('utf-8', errors='ignore').strip()
                    value_descriptions.append(value_description)
                    description_index += 12  # Move to next description

                default_value = setting_byte >> 4  # Upper 4 bits for the default value
                simple_settings.append(SimpleSetting(description, default_value, value_descriptions))
        
        return simple_settings



    def read_binary_file(self, filename):
        with open(filename, 'rb') as f:
            return f.read()

    def check_neogeo_special_string_in_rom(self, data):
        neo_geo_byteswapped = b'EN-OEG'
        index = data.find(neo_geo_byteswapped)
        if index == 256: # 256 (hex: 0x100) is where the string should be found
            return index
        else:
            return -1
        
    def get_softdip_settings_pointer_from_rom(self, data, country: str):
        # default value is JP
        dip_pointer_bytes = data[0x116:0x116 + 4]

        if country == "JP": dip_pointer_bytes = data[0x116:0x116 + 4]
        if country == "US": dip_pointer_bytes = data[0x11A:0x11A + 4]
        if country == "EU": dip_pointer_bytes = data[0x11E:0x11E + 4]

        byteswapped = dip_pointer_bytes[2:4] + dip_pointer_bytes[0:2]
        dip_pointer = struct.unpack('<L', byteswapped)[0]
        #print(f'Pointer to DIP settings: {hex(dip_pointer)}')
        return dip_pointer


#############################################################
if __name__ == "__main__":
    dips = SoftDipsSettings("dips.yaml", "debug_dips.yaml")
    game = 'bstars'
    if dips.game_settings_found(game_code=game, region='EU') == False:
        dips.enrich_softdip_settings_from_rom(game, f'./rom/{game}.zip', 'EU')
        dips.print_settings(game, 'EU')
        dips.generate_settings_image(game_code=game, region="EU", path="./")