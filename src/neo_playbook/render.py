"""
PDF renderer: reads enriched data/games.json + local images and produces 
the Neo-Playbook PDF. No network calls.

Usage:
    uv run python -m neo_playbook render
"""

import datetime
import json
import os

from fpdf import FPDF, HTMLMixin
from neo_playbook.img_tools import (
    clean_JPG,
    footer_effect,
    getImgAspectRatio,
    crop_bottomright,
    add_scanlines,
    crop_upright,
    getImgSize,
    image_resize,
)
from neo_playbook.paths import (
    GAMES_JSON, IMAGES_DIR, ICONS_DIR, CACHE_DIR, PDF_DIR,
    FONT_OSAKA, FONT_ERBOS, TEMPLATES_DIR,
)

DATA_FILE = str(GAMES_JSON)
NEOGEO_MAG_OUTPUT_PDF_PAGESMAX = 90

ct = datetime.datetime.now()
NEOGEO_MAG_OUTPUT_PDF = str(PDF_DIR / ("neo-playbook-alpha-" + str(ct.timestamp())[0:9]))


############################################################################
# PDF helpers
############################################################################


class MyFPDF(FPDF, HTMLMixin):
    pass


def add_cover_page(pdf):
    pdf.add_page()
    pdf.set_xy(0, 70)
    pdf.image(str(CACHE_DIR / "temp-page1.png"), x=None, y=None, w=210, h=0, type="", link="")
    pdf.set_xy(0, 15)
    pdf.image(str(IMAGES_DIR / "cover-title-1.png"), x=None, y=None, w=210, h=0, type="", link="")


def add_credits(pdf):
    pdf.add_page()
    pdf.image(str(IMAGES_DIR / "neo-playbook-credits.png"), x=0, y=0, w=210, h=297, type="", link="")
    pdf.set_font("ErbosDracoNova", size=20)
    pdf.set_text_color(12, 23, 34)
    pdf.set_xy(0, 12)
    pdf.cell(w=210, h=12, txt="INSERT COIN", ln=0, align="C")
    pdf.set_font("Osaka", size=10)
    f = open(str(TEMPLATES_DIR / "credits.html"), "r")
    html_text = f.read()
    f.close()
    pdf.set_xy(40, 45)
    pdf.set_left_margin(35)
    pdf.set_right_margin(35)


def _local_path(game, image_key):
    """Get local image path from the game dict, or None."""
    img = game.get("images", {}).get(image_key, {})
    path = img.get("local")
    if path and os.path.exists(path):
        return path
    return None


def set_page_background(pdf, game, page_num):
    pdf.set_left_margin(5)
    pdf.set_fill_color(123, 134, 145)
    pdf.rect(0, 0, 210, 297, "F")

    if (page_num % 2) == 0:
        MAIN_POSX = 13 + 5
        BAR_POSX = 175
        FOOTER_POSX = 5 + 5
    else:
        MAIN_POSX = 40 - 5
        BAR_POSX = 0
        FOOTER_POSX = 35 - 5

    # Game background in footer
    bg_path = _local_path(game, "background")
    if bg_path is not None:
        bg_h = 40
        bg_w = 160
        pic = clean_JPG(bg_path)
        vshift = game.get("background_vshift", 0)
        crop_upright(pic, bg_w / bg_h, vshift=vshift)
        add_scanlines(pic)
        footer_effect(pic, (123, 134, 145))
        pdf.image(pic, x=FOOTER_POSX, y=297 - bg_h, w=bg_w, h=bg_h, type="", link="")

    # Page background margins
    if (page_num % 2) == 0:
        pdf.set_xy(0, 0)
        pdf.image(str(IMAGES_DIR / "margin-left-2-darkbluesc19.png"), x=None, y=None, w=0, h=297, type="", link="")
        pdf.set_xy(133, 0)
        pdf.image(str(IMAGES_DIR / "margin-right-2-redsc19.png"), x=None, y=None, w=0, h=297, type="", link="")
    else:
        pdf.set_xy(0, 0)
        pdf.image(str(IMAGES_DIR / "margin-left-2-redsc19.png"), x=None, y=None, w=0, h=297, type="", link="")
        pdf.set_xy(161, 0)
        pdf.image(str(IMAGES_DIR / "margin-right-2-darkbluesc19.png"), x=None, y=None, w=0, h=297, type="", link="")

    # Page number in footer
    if page_num is not None:
        pdf.set_text_color(255, 240, 240)
        pdf.set_font("ErbosDracoNova", size=8)
        pdf.set_xy(BAR_POSX + 5, 290)
        pdf.cell(w=25, h=6, txt=str(page_num), ln=0, align="C")


def add_moveslist_page(pdf, command_files, game, page_num):
    def add_title():
        pdf.set_y(11)
        pdf.set_x(5)
        pdf.set_text_color(12, 23, 34)
        pdf.set_font("ErbosDracoNova", size=10)
        page_title = game["title"]
        pdf.cell(w=200, h=9, txt=page_title, ln=1, align="C")

    pdf.add_page()
    added_pages = 1

    set_page_background(pdf, game, page_num + added_pages)

    pdf.set_font("ErbosDracoNova", size=8)
    pdf.set_text_color(12, 23, 34)
    add_title()

    TOP_MARGIN = 20
    BLOCKS_MARGIN = 3
    BLOCK_WIDTH = 60
    PAGE_H = 292
    if ((page_num + added_pages) % 2) == 0:
        LEFT_MARGIN = 20
    else:
        LEFT_MARGIN = 6

    current_column = 0
    col0_y = TOP_MARGIN
    col1_y = TOP_MARGIN
    col2_y = TOP_MARGIN

    for command_file in command_files:
        im_w, im_h = getImgSize(command_file)

        if (im_h / im_w * BLOCK_WIDTH) + min(col0_y, col1_y, col2_y) > PAGE_H:
            pdf.add_page()
            added_pages += 1
            if ((page_num + added_pages) % 2) == 0:
                LEFT_MARGIN = 20
            else:
                LEFT_MARGIN = 6
            set_page_background(pdf, game, page_num + added_pages)
            add_title()
            current_column = 0
            col0_y = TOP_MARGIN
            col1_y = TOP_MARGIN
            col2_y = TOP_MARGIN

        filename = command_file
        im_x = LEFT_MARGIN + current_column * (BLOCK_WIDTH + BLOCKS_MARGIN)
        if current_column == 0:
            im_y = col0_y
        if current_column == 1:
            im_y = col1_y
        if current_column == 2:
            im_y = col2_y
        im_y += BLOCKS_MARGIN
        pdf.image(
            filename,
            x=im_x,
            y=im_y,
            w=BLOCK_WIDTH,
            h=round(BLOCK_WIDTH * im_h / im_w),
            type="",
            link="",
        )

        if current_column == 0:
            col0_y += round(BLOCK_WIDTH * im_h / im_w) + BLOCKS_MARGIN
        if current_column == 1:
            col1_y += round(BLOCK_WIDTH * im_h / im_w) + BLOCKS_MARGIN
        if current_column == 2:
            col2_y += round(BLOCK_WIDTH * im_h / im_w) + BLOCKS_MARGIN
        if col2_y <= min(col0_y, col1_y):
            current_column = 2
        if col1_y <= min(col0_y, col2_y):
            current_column = 1
        if col0_y <= min(col1_y, col2_y):
            current_column = 0

    return added_pages


############################################################################
def add_game_page(pdf, game, page_num):
    pdf.add_page()
    pdf.set_left_margin(5)
    pdf.set_fill_color(123, 134, 145)
    pdf.rect(0, 0, 210, 297, "F")

    if (page_num % 2) == 0:
        MAIN_POSX = 13 + 5
        BAR_POSX = 175
        FOOTER_POSX = 5 + 5
    else:
        MAIN_POSX = 40 - 5
        BAR_POSX = 0
        FOOTER_POSX = 35 - 5

    # Game background in footer
    bg_path = _local_path(game, "background")
    if bg_path is not None:
        bg_h = 40
        bg_w = 160
        pic = clean_JPG(bg_path)
        vshift = game.get("background_vshift", 0)
        crop_upright(pic, bg_w / bg_h, vshift=vshift)
        add_scanlines(pic)
        footer_effect(pic, (123, 134, 145))
        pdf.image(pic, x=FOOTER_POSX, y=297 - bg_h, w=bg_w, h=bg_h, type="", link="")

    # Page background margins
    if (page_num % 2) == 0:
        pdf.set_xy(0, 0)
        pdf.image(
            str(IMAGES_DIR / "margin-left-2-darkbluesc19.png"), x=None, y=None, w=0, h=297, type="", link=""
        )
        pdf.set_xy(133, 0)
        pdf.image(
            str(IMAGES_DIR / "margin-right-2-redsc19.png"), x=None, y=None, w=0, h=297, type="", link=""
        )
    else:
        pdf.set_xy(0, 0)
        pdf.image(
            str(IMAGES_DIR / "margin-left-2-redsc19.png"), x=None, y=None, w=0, h=297, type="", link=""
        )
        pdf.set_xy(161, 0)
        pdf.image(
            str(IMAGES_DIR / "margin-right-2-darkbluesc19.png"),
            x=None,
            y=None,
            w=0,
            h=297,
            type="",
            link="",
        )

    # Page number in footer
    if page_num is not None:
        pdf.set_text_color(255, 240, 240)
        pdf.set_font("ErbosDracoNova", size=8)
        pdf.set_xy(BAR_POSX + 5, 290)
        pdf.cell(w=25, h=6, txt=str(page_num), ln=0, align="C")

    # Label for title
    pdf.set_xy(5, 8)
    pdf.set_text_color(20, 20, 20)
    pdf.image(str(IMAGES_DIR / "mvs-empty-label-03.png"), x=None, y=None, w=200, h=0, type="", link="")

    # Game title
    pdf.set_y(13)
    pdf.set_font("Osaka", size=20)
    pdf.cell(w=200, h=9, txt=game["title"], ln=1, align="C")

    # Game title in Japanese
    alt_title = game.get("alt_title") or " "
    pdf.set_font("Osaka", size=14)
    pdf.cell(200, 4, txt=alt_title, ln=2, align="C")

    # Year & Publisher
    pdf.set_font("Osaka", size=8)
    year = game.get("year") or ""
    publisher = game.get("publisher") or ""
    pdf.cell(w=200, h=3, txt=f"{year} {publisher}            ", ln=2, align="R")

    # NGH/NGM ID (Neo Geo specific)
    ngm_id = game.get("platform_specific", {}).get("ngm_id")
    if ngm_id is not None and isinstance(ngm_id, int):
        pdf.set_font("Osaka", size=8)
        pdf.set_xy(21, 26)
        if ngm_id < 10:
            ngm_id_txt = "00" + str(ngm_id)
        elif ngm_id < 100:
            ngm_id_txt = "0" + str(ngm_id)
        else:
            ngm_id_txt = str(ngm_id)
        pdf.cell(w=10, h=3, txt="NGM-" + ngm_id_txt, ln=0, align="L")

    pdf.set_line_width(0.5)
    pdf.set_draw_color(0, 0, 0)

    # Wallpaper
    WALLPAPER_X = MAIN_POSX + 30
    WALLPAPER_Y = 35
    WALLPAPER_H = 70
    WALLPAPER_W = 127
    pic = _local_path(game, "wallpaper")
    if pic is not None:
        crop_bottomright(pic, WALLPAPER_W / WALLPAPER_H)
        pdf.image(pic, x=WALLPAPER_X, y=WALLPAPER_Y, w=WALLPAPER_W, h=WALLPAPER_H, type="", link="")
        pdf.rect(WALLPAPER_X, WALLPAPER_Y, w=WALLPAPER_W, h=WALLPAPER_H)

    # 3D cover
    pdf.set_xy(MAIN_POSX, 40)
    cover3d_path = _local_path(game, "cover3d")
    if cover3d_path is not None:
        cover3d_url = game.get("images", {}).get("cover3d", {}).get("url", "")
        if cover3d_url and cover3d_url.upper().endswith("JPG"):
            clean_JPG(cover3d_path)
        if cover3d_url and cover3d_url.upper().endswith("WEBP"):
            cover3d_path = clean_JPG(cover3d_path)
        pdf.image(cover3d_path, x=None, y=None, w=35, h=0, type="", link="")

    # Screenshots
    SCREENSHOT2_X = MAIN_POSX
    SCREENSHOT2_Y = 107
    SCREENSHOT2_H = 78
    SCREENSHOT2_W = round(SCREENSHOT2_H * 320 / 240)

    SCREENSHOT1_X = SCREENSHOT2_X + SCREENSHOT2_W + 2
    SCREENSHOT1_Y = SCREENSHOT2_Y
    SCREENSHOT1_H = 38
    SCREENSHOT1_W = round(SCREENSHOT1_H * 320 / 240)

    SCREENSHOT3_X = SCREENSHOT1_X
    SCREENSHOT3_Y = SCREENSHOT1_Y + SCREENSHOT2_H - SCREENSHOT1_H
    SCREENSHOT3_W = SCREENSHOT1_W
    SCREENSHOT3_H = SCREENSHOT1_H

    # Handle screenshot inversion
    ss_main_key = "screenshot_main"
    ss_alt_key = "screenshot_alt"
    if game.get("invert_screenshots"):
        ss_main_key, ss_alt_key = ss_alt_key, ss_main_key

    pic = _local_path(game, ss_main_key)
    if pic is not None:
        crop_bottomright(pic, SCREENSHOT2_W / SCREENSHOT2_H)
        pic = clean_JPG(pic)
        add_scanlines(pic)
        pdf.image(pic, x=SCREENSHOT2_X, y=SCREENSHOT2_Y, w=SCREENSHOT2_W, h=SCREENSHOT2_H, type="", link="")
        pdf.rect(SCREENSHOT2_X, SCREENSHOT2_Y, w=SCREENSHOT2_W, h=SCREENSHOT2_H)

    pic = _local_path(game, "screenshot_title")
    if pic is not None:
        crop_bottomright(pic, SCREENSHOT1_W / SCREENSHOT1_H)
        pic = clean_JPG(pic)
        add_scanlines(pic)
        pdf.image(pic, x=SCREENSHOT1_X, y=SCREENSHOT1_Y, w=SCREENSHOT1_W, h=SCREENSHOT1_H, type="", link="")
        pdf.rect(SCREENSHOT1_X, SCREENSHOT1_Y, w=SCREENSHOT1_W, h=SCREENSHOT1_H)

    pic = _local_path(game, ss_alt_key)
    if pic is not None:
        crop_bottomright(pic, SCREENSHOT3_W / SCREENSHOT3_H)
        pic = clean_JPG(pic)
        add_scanlines(pic)
        pdf.image(pic, x=SCREENSHOT3_X, y=SCREENSHOT3_Y, w=SCREENSHOT3_W, h=SCREENSHOT3_H, type="", link="")
        pdf.rect(SCREENSHOT3_X, SCREENSHOT3_Y, w=SCREENSHOT3_W, h=SCREENSHOT3_H)

    # Mini marquee
    MINI_MARQUEE_X = SCREENSHOT1_X
    MINI_MARQUEE_Y = SCREENSHOT3_Y + SCREENSHOT3_H + (SCREENSHOT3_Y - (SCREENSHOT1_Y + SCREENSHOT3_H))
    MINI_MARQUEE_W = SCREENSHOT1_W
    MINI_MARQUEE_H = MINI_MARQUEE_W / 11 * 13.75

    pic = _local_path(game, "mini_marquee")
    if pic is not None:
        crop_bottomright(pic, MINI_MARQUEE_W / MINI_MARQUEE_H)
        pdf.image(pic, x=MINI_MARQUEE_X, y=MINI_MARQUEE_Y, w=MINI_MARQUEE_W, h=MINI_MARQUEE_H, type="", link="")
        pdf.rect(MINI_MARQUEE_X, MINI_MARQUEE_Y, w=MINI_MARQUEE_W, h=MINI_MARQUEE_H)

    # Game soft dips options (Neo Geo specific)
    softdips = game.get("softdips_image")
    if softdips and os.path.exists(softdips):
        pic = clean_JPG(softdips)
        pic = image_resize(pic, 640)
        add_scanlines(pic)
        imw, imh = getImgSize(pic)
        SOFTDIPS_X = SCREENSHOT1_X
        SOFTDIPS_Y = MINI_MARQUEE_Y + MINI_MARQUEE_H + 2
        SOFTDIPS_W = SCREENSHOT1_W
        SOFTDIPS_H = SOFTDIPS_W / imw * imh
        pdf.image(pic, x=SOFTDIPS_X, y=SOFTDIPS_Y, w=SOFTDIPS_W, type="", link="")
        pdf.rect(SOFTDIPS_X, SOFTDIPS_Y, w=SOFTDIPS_W, h=SOFTDIPS_H)

    # Horizontal line
    pdf.set_fill_color(47, 61, 73)
    pdf.rect(SCREENSHOT2_X, MINI_MARQUEE_Y, SCREENSHOT1_W, 1, "F")

    # Game description
    description = game.get("description")
    if description is not None:
        pdf.set_font("Osaka", size=7)
        pdf.set_xy(SCREENSHOT2_X, MINI_MARQUEE_Y + 3)
        pdf.set_text_color(47, 61, 73)
        pdf.multi_cell(w=SCREENSHOT2_W, h=3, txt=description, align="J")

    # Table with MAME versions
    pdf.set_fill_color(47, 61, 73)
    pdf.rect(SCREENSHOT2_X, pdf.get_y() + 3, SCREENSHOT2_W, 1, "F")
    pdf.set_font("ErbosDracoNova", size=8)
    pdf.set_xy(SCREENSHOT2_X, pdf.get_y() + 5)
    pdf.cell(w=17, h=7, txt="versions / roms", ln=0, align="L")
    for version in game.get("roms", []):
        pdf.set_xy(SCREENSHOT2_X, pdf.get_y() + 4)
        pdf.set_font("ErbosDracoNova", size=6)
        ROMNAME_W = 17
        pdf.cell(w=ROMNAME_W, h=5, txt=version.get("rom_name") or "", ln=0, align="L")
        pdf.set_font("Osaka", size=6)
        pdf.cell(
            w=SCREENSHOT2_W - ROMNAME_W,
            h=5,
            txt=version.get("description") or "",
            ln=0,
            align="L",
        )

    # MEGs (size of NeoGeo cart — Neo Geo specific)
    megs = game.get("platform_specific", {}).get("megs")
    if megs is not None:
        pdf.image(str(IMAGES_DIR / "MEGs.png"), x=BAR_POSX + 5, y=70, w=25, h=0, type="", link="")
        pdf.set_font("ErbosDracoNova", size=20)
        pdf.set_xy(BAR_POSX + 6, 71)
        pdf.cell(w=25, h=20, txt=str(megs), ln=0, align="C")

    # Type of game (homebrew, proto, licenced...)
    game_type = game.get("type")
    if game_type is not None:
        icon_ok = True
        match game_type:
            case "Licenced":
                gametype_icon = str(ICONS_DIR / "type-licenced.png")
            case "Homebrew":
                gametype_icon = str(ICONS_DIR / "type-homebrew.png")
            case "Unreleased":
                gametype_icon = str(ICONS_DIR / "type-unreleased.png")
            case "Unlicenced":
                gametype_icon = str(ICONS_DIR / "type-unlicenced.png")
            case "Hack":
                gametype_icon = str(ICONS_DIR / "type-hack.png")
            case "intro demo":
                gametype_icon = str(ICONS_DIR / "type-intro-demo.png")
            case "Bootleg":
                gametype_icon = str(ICONS_DIR / "type-bootleg.png")
            case "Port":
                gametype_icon = str(ICONS_DIR / "type-port.png")
            case _:
                icon_ok = False
        if icon_ok:
            pdf.image(gametype_icon, x=BAR_POSX + 5, y=110, w=25, h=0, type="", link="")

    # Game platforms
    platforms = game.get("platforms")
    if platforms is not None:
        filename = str(ICONS_DIR / ("platform-" + platforms + ".png"))
        if os.path.exists(filename):
            pdf.image(filename, x=BAR_POSX + 5, y=140, w=25, h=0, type="", link="")

    # Genre of game
    genre = game.get("genre")
    if genre is not None:
        icon_ok = True
        match genre:
            case "Sport":
                gamegenre_icon = str(ICONS_DIR / "genre-sport.png")
            case "Divers":
                gamegenre_icon = str(ICONS_DIR / "genre-misc.png")
            case "Shoot them up":
                gamegenre_icon = str(ICONS_DIR / "genre-shootthemup.png")
            case "Shooter":
                gamegenre_icon = str(ICONS_DIR / "genre-shootthemup.png")
            case "Combat":
                gamegenre_icon = str(ICONS_DIR / "genre-combat.png")
            case "Reflexion":
                gamegenre_icon = str(ICONS_DIR / "genre-reflexion.png")
            case "Plate-formes":
                gamegenre_icon = str(ICONS_DIR / "genre-platformer.png")
            case "Quiz":
                gamegenre_icon = str(ICONS_DIR / "genre-quizz.png")
            case "Puzzle-Game":
                gamegenre_icon = str(ICONS_DIR / "genre-puzzle.png")
            case "Run and gun":
                gamegenre_icon = str(ICONS_DIR / "genre-runngun.png")
            case "Beat them all":
                gamegenre_icon = str(ICONS_DIR / "genre-beatthemall.png")
            case "Action":
                gamegenre_icon = str(ICONS_DIR / "genre-action.png")
            case "Course":
                gamegenre_icon = str(ICONS_DIR / "genre-racing.png")
            case "RPG":
                gamegenre_icon = str(ICONS_DIR / "genre-rpg.png")
            case _:
                icon_ok = False
        if icon_ok:
            pdf.image(gamegenre_icon, x=BAR_POSX + 5, y=170, w=25, h=0, type="", link="")

    # Number of players
    nb_players = game.get("nb_players")
    if nb_players is not None:
        pdf.image(str(ICONS_DIR / "placeholder-blue.png"), x=BAR_POSX + 5, y=200, w=25, h=0, type="", link="")
        pdf.set_text_color(255, 240, 240)
        pdf.set_font("ErbosDracoNova", size=8)
        pdf.set_xy(BAR_POSX + 3, 210)
        if nb_players == "2P":
            pdf.cell(w=30, h=7, txt="2 PLAYERS", ln=0, align="C")
        if nb_players == "1P":
            pdf.cell(w=30, h=7, txt="1 PLAYER", ln=0, align="C")


############################################################################
# Main
############################################################################


def main():
    # Load data
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        entries = json.load(f)

    games = [e for e in entries if e.get("page_type") == "game"]
    print(f"Loaded {len(entries)} entries ({len(games)} games)")

    # Init PDF
    pdf = MyFPDF(unit="mm", format="A4")
    pdf.compress = True
    pdf.set_left_margin(5)
    pdf.set_top_margin(0)
    pdf.set_auto_page_break(auto=0)
    pdf.add_font("Osaka", "", str(FONT_OSAKA), uni=True)
    pdf.add_font("ErbosDracoNova", "", str(FONT_ERBOS), uni=True)

    page_num = -1  # starts at -1 because of cover

    for entry in entries:
        page_num += 1
        page_type = entry.get("page_type")

        match page_type:
            case "cover_1":
                print("# cover page")
                add_cover_page(pdf)

            case "blank":
                print("# blank page")
                pdf.add_page()

            case "credits":
                print("# credits page")
                add_credits(pdf)

            case "game":
                title = entry.get("title", "???")
                generation = entry.get("generation")

                print(f"# game page: {title}...", end="")

                # Render game page
                add_game_page(pdf, entry, page_num)

                # Render moves list pages if available
                command_files = entry.get("command_blocks", [])
                # Filter to only existing files
                command_files = [f for f in command_files if os.path.exists(f)]
                if command_files:
                    added_pages = add_moveslist_page(pdf, command_files, entry, page_num)
                    page_num += added_pages
                    print(f" + {added_pages} moves pages", end="")

                print(" done")

            case _:
                break

    # Write PDF
    filename = NEOGEO_MAG_OUTPUT_PDF + ".pdf"
    print(f"\n# writing PDF file: {filename}")
    pdf.output(filename)
    print("Done.")


if __name__ == "__main__":
    main()
