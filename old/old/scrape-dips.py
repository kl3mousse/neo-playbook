import requests
from bs4 import BeautifulSoup
import re
import yaml

def write_to_yaml(data, filename):
    with open(filename, 'w') as file:
        yaml.dump(data, file)

def scrape_neogeo_dipswitch_data(game_list):
    games_data = {}
    for url in game_list:
        response = requests.get(url)
        soup = BeautifulSoup(response.content, 'html.parser')

    
        game_sections = soup.find_all(['h2', 'p'])  # find all h2 and p tags
        game_name = None
        dipswitch_data = None
        
        for tag in game_sections:
            if tag.name == 'h2':
                # Save the previous game's data if any
                if game_name and dipswitch_data:
                    games_data[game_name] = dipswitch_data
                # Start new game data
                game_name = tag.text.strip()
                dipswitch_data = {"1": {}, "2": {}}
            elif tag.name == 'p' and game_name:
                # Process the paragraph text to extract dipswitch data
                lines = tag.text.strip().split('\n')
                for line in lines:
                    match = re.match(r'(\d-\d) (.+)', line)
                    if match:
                        bank, switch = match.group(1).split('-')
                        description = match.group(2)
                        if bank in ['1', '2']:
                            dipswitch_data[bank][switch] = description  # Only add data if bank is '1' or '2'
        
        # Save the last game's data
        if game_name and dipswitch_data:
            games_data[game_name] = dipswitch_data
    
    return games_data



game_list = [  
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Art of Fighting",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Art of Fighting 2",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Art of Fighting 3",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Breakers [evilwasabi]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Breakers Revenge",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Double Dragon",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Fatal Fury 2 [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Fatal Fury 3 [ne7+kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Fatal Fury Special [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Garou Mark of the Wolves",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Iron Clad [SuperGun + Xian Xi]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Kabuki Klash / Far East of Eden [ne7+kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters 2000 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters 2001 [kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters 2002 [MR Sakaki]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters 2003",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters '94 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters '95 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters '96 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters '97 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters '98 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of Fighters '99 [bonuskun / Thomas Giboin]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#King of the Monsters 2 [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Last Blade [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Last Blade 2 [kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Metal Slug [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Metal Slug 2 [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Metal Slug 3 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Metal Slug 4",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Metal Slug 5 [hellishtempura]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Metal Slug X [Wasabi]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Money Puzzle Exchanger [ne7+Kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Neo Drift Out [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Neo Turf Masters / Big Tournament Golf [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Pleasure Goal [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Puzzle Bobble / Bust A Move [kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Real Bout Fatal Fury [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Real Bout Fatal Fury 2 [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Real Bout Fatal Fury Special [Meta-Ukyo]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Robo Army [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Samurai Shodown",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Samurai Shodown II [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Samurai Shodown IV [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Samurai Shodown V [kagami007]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Samurai Shodown V: Special",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Samurai Showdown III [bonuskun]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Savage Reign",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Shock Troopers 2 [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#SNK vs Capcom Chaos",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Top Hunter [ne7]",
    "https://www.neo-geo.com/wiki/index.php?title=Neo-Geo_Big_List_of_Debug_Dipswitches#Ultimate 11 / Super Sidekicks 4 [ne7]",
]

dipswitch_data = scrape_neogeo_dipswitch_data(game_list)
write_to_yaml(dipswitch_data, 'debug_dips.yaml')