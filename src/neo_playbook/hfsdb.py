import requests
import json
import time

from neo_playbook.paths import SECRETS_FILE

# loading secrets from local file
with open(SECRETS_FILE) as f:
    _secrets = json.load(f)
HFSDB_APP_ACCESS_TOKEN = _secrets["HFSDB_APP_ACCESS_TOKEN"]

# request counter, used to measure how frequent the API is called
hfs_api_counter = 0


def get_game_from_hfsdb(hfs_game_id):
    global hfs_api_counter

    url = "https://db.hfsplay.fr/api/v1/games/" + str(hfs_game_id)

    headers = {
        'Authorization': 'Bearer ' + HFSDB_APP_ACCESS_TOKEN,
    }

    hfs_api_counter += 1
    time.sleep(5)
    response = requests.request("GET", url, headers=headers)

    try:
        game = response.json()
        return game
    except requests.HTTPError as exception:
        print(exception)
        print("HFSdb API error (after " + str(hfs_api_counter) + " API calls)")
        return None
