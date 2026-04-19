from igdb.wrapper import IGDBWrapper
import json

f = open('secrets.json')
secrets=json.load(f)
IGDB_CLIENT_ID=secrets["IGDB_CLIENT_ID"]
IGDB_APP_ACCESS_TOKEN=secrets["IGDB_APP_ACCESS_TOKEN"]
f.close()

# connect to IGDB
wrapper = IGDBWrapper(IGDB_CLIENT_ID, IGDB_APP_ACCESS_TOKEN)
# get IGDB data for game in JSON format
gamejson = wrapper.api_request('games','fields *; where id = 10500;')
gamedata = json.loads(gamejson)
# get info from that JSON
print(gamedata[0]['id'])
print(gamedata[0]['name'])
