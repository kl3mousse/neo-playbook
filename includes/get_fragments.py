import requests
from bs4 import BeautifulSoup
import wikipediaapi
import json

# loading secrets from local file
f = open('secrets.json')
secrets=json.load(f)
HFSDB_APP_ACCESS_TOKEN=secrets["HFSDB_APP_ACCESS_TOKEN"]
f.close()

def get_wikisummary(wikipage_name):
    wiki_wiki = wikipediaapi.Wikipedia('en')
    page_py = wiki_wiki.page(wikipage_name)

    return page_py.summary

def get_wikisummary_old(wikipage_url):
    page = requests.get(wikipage_url)
    
    soup = BeautifulSoup(page.content, "html.parser")
    results = soup.find(id="mw-content-text")
    txt  = results.find("div", class_="mw-parser-output")
    wiki_summary = txt.find_all("p") 
    
    return wiki_summary[0].get_text()
    
def get_game_from_hfsdb(hfs_game_id):
    url = "https://db.hfsplay.fr/api/v1/games/" + str(hfs_game_id)
    
    payload={}
    headers = {
        'Authorization': 'Bearer '+HFSDB_APP_ACCESS_TOKEN,
        }
    response = requests.request("GET", url, headers=headers, data=payload)
    print(response.text)

