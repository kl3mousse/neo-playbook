# neo-playbook
an opensource python program that scraps pictures &amp; texts on the web, to create a PDF that lists all known Neo Geo games.

As a kid, I've always spent so much time reading magazines about videogames. I wanted here to recreate that experience for the arcade games I'm playing, starting with NeoGeo games. We have a habit at home with my kids, we only change games once a month, unplug the Jammas or MVS carts and pick new ones once. 
I wanted a little book showing all NeoGeo games, so that we can have a look in advance and pick our favorite on Day 1.

# how it works

- an index of all inventoried games is managed in an excel file
- some metadata is managed there (name, game type, ...), as well as related identifiers on various databases (wikimedia, hfsdb, igdb...)
- a python program has to be run manually from your computer, that scraps all game data and loads that into a PDF

# example of output

![neo playbook sample image](https://github.com/kl3mousse/neo-geo-game-mag/blob/main/img/neo-playbook-proto.png)
