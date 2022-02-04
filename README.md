# neo-playbook
an opensource python program that scraps pictures &amp; texts on the web, to create a PDF that lists all known Neo Geo games.

As a kid, I've always spent so much time reading magazines about videogames. I wanted here to recreate that experience for the arcade games I'm playing, starting with NeoGeo games. We have a habit at home with my kids, we only change games once a month, unplug the Jammas or MVS carts and pick new ones once. 
I wanted a little book showing all NeoGeo games, so that we can have a look in advance and pick our favorite on Day 1.

# current status

in development. Prototype looks good enough to be shared publicly. Contributions welcome (create an issue to raise the hand).
Done
- all games from NeoGeo era (~90's) are there
- visuals & texts OK
To Do list
- crediting various indirect sources, platforms & contributors which made medias available on the net. This book is only scraping their work, these folks deserve thanks.
- crediting opensource software properly
- games from NeoGeo resurrection era (2000-2020), in progress
- additional metadata & graphical elements for each game (genre, type, sizes, platforms, ...)
- summary page / table of all games
- versionning of PDF
- ensuring translations are available in English & French for all games. More languages (then plz ask for it...) maybe?
- footers for all games 

# how it works

- an index of all inventoried games is managed in an excel file
- some metadata is managed there (name, game type, ...), as well as related identifiers on various databases (wikimedia, hfsdb, fgbg.art, igdb...)
- a python program has to be run manually from your computer, that scraps all game data and loads that into a PDF

# example of output

![neo playbook sample image](https://github.com/kl3mousse/neo-geo-game-mag/blob/main/img/neo-playbook-proto.png)
