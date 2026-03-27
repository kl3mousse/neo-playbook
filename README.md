# neo-playbook
an opensource python program that scraps pictures &amp; texts on the web, to create a PDF that lists all known Neo Geo games.

As a kid, I've always spent so much time reading magazines about videogames. I wanted here to recreate that experience for the arcade games I'm playing, starting with NeoGeo games. We have a habit at home with my kids, we only change games once a month, unplug the Jammas or MVS carts and pick new ones once. 
I wanted a little book showing all NeoGeo games, so that we can have a look in advance and pick our favorite on Day 1.

# current status

in development. Prototype looks good enough to be shared publicly, have a look at the alpha version in the github releases. Contributions welcome (create an issue to raise the hand).
Done
- all games from NeoGeo era (~90's) are there
- visuals & texts OK
- moves lists from MAME command.dat integrated (still lots to do to get it nicely loaded)

To Do list: now moved to Github issues for better tracking!

# prerequisites

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- a `secrets.json` file (copy `secrets_sample.json` and fill in your API keys)

# setup

```bash
# install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# install dependencies
uv sync

# copy secrets template and fill in your API keys
cp secrets_sample.json secrets.json
```

# run

```bash
# Step 1: Fetch remote data (HFSdb API, images, soft DIPs, command blocks)
uv run python fetch_data.py

# Step 2: Generate the PDF from the enriched data
uv run python render_pdf.py
```

# how it works

The project is split into a **data pipeline** and a **PDF renderer**, connected by a single JSON file (`data/games.json`):

1. **`data/games.json`** — the source of truth. Contains all game entries (title, year, publisher, ROM versions, image URLs/paths, etc.). Edit this file to add or modify games.
2. **`fetch_data.py`** — reads `data/games.json`, enriches it with data from the HFSdb API (descriptions, screenshots, covers), downloads images, extracts Neo Geo soft DIP settings from ROM files, and generates command block PNGs from MAME's command.dat. Writes the enriched data back to `data/games.json`. Idempotent — skips already-populated entries.
3. **`render_pdf.py`** — reads the enriched `data/games.json` and local image files, produces an A4 PDF magazine. No network calls.

# example of output

![neo playbook sample image](https://github.com/kl3mousse/neo-geo-game-mag/blob/main/img/neo-playbook-proto.png)
