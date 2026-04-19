import wikipediaapi
import wikipedia
import openpyxl            # to handle reading from XLS file
from openpyxl import load_workbook
import requests
from bs4 import BeautifulSoup

from mediawikiapi import MediaWikiAPI
mediawikiapi = MediaWikiAPI()
print(mediawikiapi.summary('Windjammers (video_game)'))

#wiki_wiki = wikipediaapi.Wikipedia('en')
#page_py = wiki_wiki.page('Windjammers_(video_game)')

#print(page_py.text)

#print("Page - Title: %s" % page_py.title)
#print("Page - Summary: %s" % page_py.summary)

#print(wikipedia.page(wikipedia.search("Metal Slug")[0]).url)

#page_wiki = wikipedia.page(wikipedia.search(query="Windjammers_(video_game)", results=1, suggestion=True))
#print(page_wiki.title)
#img = page_wiki.images[0]

#print(img)


    ####################################################
    # Scraping data from IGDB
    if game_igdb_id is not None:
        wrapper = IGDBWrapper(IGDB_CLIENT_ID, IGDB_APP_ACCESS_TOKEN)
        # get IGDB data for game in JSON format
        gamejson = wrapper.api_request('games','fields *, cover.url, screenshots.url; where id = ' + str(game_igdb_id) + ';')
        gamedata = json.loads(gamejson)
        # get info from that JSON
        #print(gamedata[0]['id'])
        #print(gamedata[0]['name'])
        game_igdb_summary   = gamedata[0].get('summary', 'no IGDB summary')
        game_igdb_storyline = gamedata[0].get('storyline','no IGDB storyline')
        game_igdb_cover_id  = gamedata[0]['cover']['url']
        if gamedata[0].get('screenshots', None) is not None:
            game_igdb_screenshot1 = gamedata[0].get('screenshots','no IGDB storyline')[0].get('url', 'screenshot 0 exists, but no URL')

        game_cover_front = 'https:' + game_igdb_cover_id.replace("t_thumb","t_original")
        game_screenshot_main = 'https:' + game_igdb_screenshot1.replace("t_thumb","t_original")
        game_storyline = game_igdb_storyline