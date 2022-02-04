import requests
import json

# loading secrets from local file
f = open('secrets.json')
secrets=json.load(f)
HFSDB_APP_ACCESS_TOKEN=secrets["HFSDB_APP_ACCESS_TOKEN"]
f.close()

class game_mame_version:
    def __init__(self, mame_game_id, mame_game_rom, mame_game_description, mame_game_year, mame_game_publisher, mame_game_serial,mame_game_release, mame_game_platform, mame_game_compatibility):
        self.mame_game_id            = mame_game_id
        self.mame_game_rom           = mame_game_rom
        self.mame_game_description   = mame_game_description
        self.mame_game_year          = mame_game_year
        self.mame_game_publisher     = mame_game_publisher
        self.mame_game_serial        = mame_game_serial
        self.mame_game_release       = mame_game_release
        self.mame_game_platform      = mame_game_platform
        self.mame_game_compatibility = mame_game_compatibility

class game_data:
    def __init__(self, id):
        self.title      = None
        self.id         = id
        self.hfsdb_id   = None
        self.alt_title  = None
        self.year       = None
        self.publisher  = None
        self.generation = None
        self.description = None
        self.screenshot1 = None
        self.screenshot2 = None
        self.screenshot3 = None
        self.invert_ingamescreenshots = None
        self.mvs_cart = None
        self.mini_marquee = None
        self.mame_versions = []
        self.nb_players = None
        self.type = None #homebrew, proto, ...
        self.genre = None #fight, puzzle...
        self.cover3d = None
        self.wallpaper = None
        self.game_background = None
        self.vshift = None

    def addrom(self, rom):
        self.mame_versions.append(rom)

    def nbroms(self):
        return len(self.mame_versions)


def get_game_from_hfsdb(hfs_game_id):
    url = "https://db.hfsplay.fr/api/v1/games/" + str(hfs_game_id)
    
    payload={}
    headers = {
        'Authorization': 'Bearer '+HFSDB_APP_ACCESS_TOKEN,
        }
    response = requests.request("GET", url, headers=headers, data=payload)
    
    game = response.json()

    return game

def hfsdb_scraper(game_hfsdb_id):
# this function scraps data from HFSdb API, and loads into a game_data variable
    game = game_data(None)
    if game_hfsdb_id is not None:
        #get game info from HFSdb API
        hfs_game = get_game_from_hfsdb(game_hfsdb_id)

        LANG = 'FR'
        #get description
        if LANG == 'FR':
            game.description = hfs_game['description_fr']
        if LANG == 'EN':
            game.description = hfs_game['description_en']

        #get 3d cover
        game.cover3d = None
        for media in hfs_game["medias"]:
            if (media["type"] == "cover3d") and (media["file"][-3:].upper() != "GIF"):
                game.cover3d = media["file"]
                #print(game_cover3d)
                break
                
        #get number of players
        game.nb_players = None
        for metadata in hfs_game["metadata"]:
            if (metadata["id"] == 85507):
                p = metadata["value"]
                if p == "2 joueurs":
                    game.nb_players = "2P"
                else:
                    print("# players: " + p)
                break
            if (metadata["id"] == 48762):
                p = metadata["value"]
                if p == "1 joueur":
                    game.nb_players = "1P"
                else:
                    print("# players: " + p)
                break

        #get game genre (fighting, puzzle...)
        for metadata in hfs_game["metadata"]:
            if (metadata["name"] == "genre"):
                game.genre = metadata["value"]
                break
            

        #get wallpaper
        game.wallpaper = None
        for media in hfs_game["medias"]:
            #print("checking media#" + str(media["id"]))
            if (media["type"] == "wallpaper") and (media["res_y"] > 32): # and (media["file"][-3:].upper() != "GIF"):
                game.wallpaper = media["file"]
                #print(game.wallpaper)
                break

        #get screenshots
        game.screenshot1 = None #title
        game.screenshot2 = None #big screenshot
        game.screenshot3 = None #other small screenshot
        #game.invert_ingamescreenshots = game_invert_ingamescreenshots
        for media in hfs_game["medias"]:
            if (media["type"] == "screenshot") and (media["file"][-3:].upper() != "GIF"):
                if media['metadata'][0]['value'] == 'title':
                    game.screenshot1 = media["file"]
                else:
                    if game.screenshot2 is None:
                        game.screenshot2 = media["file"]
                    else:
                        if game.screenshot3 is None:
                            game.screenshot3 = media["file"]

        #get mvs cart
        game.mvs_cart = None        
        for media in hfs_game["medias"]:
            if (media["type"] == "hardware") and (media["description"] == "PCB") and (media["file"][-3:].upper() != "GIF"):
                game.mvs_cart = media["file"]

        #get mini-marquee
        game.mini_marquee = None
        for media in hfs_game["medias"]:
            if (media["type"] == "instructioncard") and (media["file"][-3:].upper() != "GIF") and (media['res_x']<media['res_y']):
                game.mini_marquee = media["file"]
                break

    return game

    
