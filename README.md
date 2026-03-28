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
- (optional) Firebase CLI — for deploying security rules
- (optional) Flutter SDK — for the admin app

# setup

```bash
# install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# install dependencies
uv sync

# copy secrets template and fill in your API keys
cp secrets_sample.json secrets.json
```

### Firebase setup (optional — for sync command)

```bash
# install firebase-admin extra
uv sync --extra firebase

# copy the service account key template
cp firebase-service-account-sample.json firebase-service-account.json
# then fill it with your real key from:
#   Firebase console → Project settings → Service accounts → Generate new private key
```

### Flutter setup (optional — for admin app)

```bash
cd app

# generate Firebase config (requires flutterfire CLI)
flutterfire configure

# install dependencies
flutter pub get
```

# run

Both commands are run via `python -m neo_playbook`:

```bash
# Step 1: Fetch remote data (HFSdb API, images, soft DIPs, command blocks)
uv run python -m neo_playbook fetch

# Step 2: Generate the PDF from the enriched data
uv run python -m neo_playbook render

# Step 3 (optional): Sync games & images to Firebase
uv run python -m neo_playbook sync          # skip already-synced games
uv run python -m neo_playbook sync --force  # re-upload everything
```

**fetch** connects to the [HFSdb API](https://db.hfsplay.fr) (requires a token in `secrets.json`), downloads images, extracts Neo Geo soft DIP settings from ROM files, and generates command-list PNGs from MAME's `command.dat`. It is idempotent — already-populated entries are skipped unless you pass `--force`.

**render** reads the enriched data and local images and produces an A4 PDF in `output/pdf/`. No network calls.

**sync** pushes game data to Firestore and uploads cached images to Firebase Storage. Requires `firebase-service-account.json` (see setup above). Skips games already in Firestore unless `--force` is passed.

# project structure

```
neo-geo-game-mag/
├── src/neo_playbook/        # Python package
│   ├── __main__.py          # entry point (fetch / render)
│   ├── paths.py             # all path constants in one place
│   ├── fetch.py             # data enrichment pipeline
│   ├── render.py            # PDF generation
│   ├── dips.py              # Neo Geo soft-DIP ROM parser
│   ├── get_image.py         # image downloader with cache
│   ├── hfsdb.py             # HFSdb API client
│   ├── img_tools.py         # PIL image transforms
│   └── mame_commands.py     # MAME command.dat → PNG
├── data/                    # all local data sources
│   ├── games.json           # ★ source of truth — edit this to add/modify games
│   ├── dips.yaml            # cached soft-DIP settings (auto-generated)
│   ├── debug_dips.yaml      # cached debug-DIP settings (auto-generated)
│   ├── command-dat/         # MAME command.dat file
│   └── rom/                 # Neo Geo ROM zips (for soft-DIP extraction)
├── assets/                  # static assets for the PDF
│   ├── fonts/
│   ├── images/              # cover, margins, icons, etc.
│   │   └── icons/           # type / genre / platform icons
│   └── templates/           # HTML templates (credits page)
├── output/                  # generated files (git-ignored)
│   ├── cache/               # downloaded images & generated PNGs
│   └── pdf/                 # final PDF output
├── pyproject.toml
├── secrets.json             # API keys (git-ignored, see secrets_sample.json)
├── firebase-service-account.json  # Firebase key (git-ignored, see *-sample.json)
├── firebase.json            # Firebase project config
├── firestore.rules          # Firestore security rules
├── storage.rules            # Storage security rules
├── app/                     # Flutter admin app (see app/README.md)
│   └── lib/
│       ├── main.dart
│       ├── models/game.dart
│       ├── services/        # auth, firestore, storage
│       ├── screens/         # login, games list, game detail
│       └── widgets/         # game card
└── README.md
```

# where to edit data

### Adding or modifying games

Edit **`data/games.json`** (git-ignored — see `data/sample_games.json` for the schema). Each game entry looks like this:

| Field | What it does | Filled by |
|---|---|---|
| `page_type` | `"game"`, `"cover_1"`, `"credits"`, or `"blank"` | you |
| `hfsdb_id` | HFSdb game ID — used by `fetch` to pull description & images | you |
| `title` / `alt_title` | Game name (English / Japanese) | you |
| `year` / `publisher` | Year of release and publisher | you |
| `type` | `Licenced`, `Homebrew`, `Unreleased`, `Bootleg`, `Hack`, `Port`, etc. | you |
| `genre` | `Combat`, `Shoot them up`, `Sport`, `Puzzle-Game`, etc. | you |
| `description` | Game description text | auto (fetch) or manual override |
| `images` | URLs + local paths for wallpaper, cover3d, screenshots, etc. | auto (fetch) |
| `roms` | ROM versions (name, description, serial). Used for soft-DIP extraction | you |
| `platform_specific.megs` | Cart size in MEGs | you |
| `platform_specific.ngm_id` | NGM catalogue number | you |
| `background_vshift` | Vertical offset for the background image crop (tweak visually) | you |
| `invert_screenshots` | Swap main and alt screenshots | you |
| `softdips_image` | Path to generated soft-DIP settings PNG | auto (fetch) |
| `command_blocks` | List of generated command-block PNG paths | auto (fetch) |

Fields marked **auto (fetch)** are populated by `uv run python -m neo_playbook fetch`. You only need to set the initial fields (title, hfsdb_id, roms, etc.) and run fetch to fill in the rest.

### Other data sources

- **`data/command-dat/command.dat`** — MAME's command.dat file. Replace it with a newer version to get updated move lists.
- **`data/rom/`** — place Neo Geo ROM zips here (e.g. `samsho.zip`). Used to extract soft-DIP settings. Only the `.p1` program ROM inside the zip is read.
- **`data/dips.yaml`** / **`data/debug_dips.yaml`** — auto-generated caches of extracted DIP settings. Delete them to force re-extraction on the next `fetch` run.

### Visual assets

- **`assets/images/`** — margin borders, cover title, MEGs icon, credits background, etc.
- **`assets/images/icons/`** — game type, genre, and platform icons shown in the sidebar.
- **`assets/fonts/`** — TTF fonts used in the PDF and in generated PNGs.
- **`assets/templates/credits.html`** — HTML template for the credits page.

# example of output

![neo playbook sample image](https://github.com/kl3mousse/neo-geo-game-mag/blob/main/img/neo-playbook-proto.png)
