import wikipediaapi
import wikipedia
import openpyxl            # to handle reading from XLS file
from openpyxl import load_workbook
import requests
from bs4 import BeautifulSoup

def get_gameinfo_test(url):
    page = requests.get(url)
    
    soup = BeautifulSoup(page.content, "html.parser")
    
    results = soup.find(id="mw-content-text")
    #print(results.prettify())

    job_elements = results.find_all("div", class_="mw-parser-output")
    print(job_elements.prettify())
    #txt = results.find_all(class="mw-parser-output")
    #print(txt)
    return 1 #results[0].get_text()

get_gameinfo_test("https://snk.fandom.com/wiki/Chibi_Maruko-chan_Deluxe_Quiz")

#wiki_wiki = wikipediaapi.Wikipedia('en')
#page_py = wiki_wiki.page('Windjammers_(video_game)')
#print("Page - Title: %s" % page_py.title)
#print("Page - Summary: %s" % page_py.summary)

#print(wikipedia.page(wikipedia.search("Metal Slug")[0]).url)
