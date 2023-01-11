#########################################################################
# a library that generates PNG files displaying moves lists / command
# lists for a given game. You need to provide a "command.dat" filepath
# and a game ID (mame/rom).
#
# example: get_command_blocks("kof2000", "./command-dat/command.dat")
#    it will return a list of filepaths to PNG files that have been
#    created (ex: ["kof2000-01.png", "kof2000-02.png"])
#
# this Lib requires a truetype font with proper symbols for Arcade
# controls (mostly arrows for Joystick, but not only). See ARCADE_FONT.
#
#########################################################################

from PIL import Image, ImageDraw, ImageFont
import textwrap

class command_block:
    def __init__(self, rom, title, num):
        self.rom              = rom
        self.block_title      = title
        self.num              = num
        self.block_rows       = []

ARCADE_FONT = './fonts/AnonymousPro-Regular-arcade-controls.ttf'

TEXT_WRAP_AT = 40
ROWS_SPACING = 45
CHARSPACING = 23

ROUNDED_RECT_RADIUS = 18
HEADER_HEIGHT = 105

HEADER_TXT_COLOR = (199, 199, 199) #(255, 255, 255)
TXTCOLOR = (0, 0, 0)
TXTCOLOR2 = (10, 10, 10)

BGCOLOR  =  (199, 199, 199) #(204, 236, 255) #(111, 122, 135) #(53, 68, 81) #( 200, 210, 240) #
HEADER_COLOR = (0, 0, 0)
SUBHEADER_COLOR = (184, 184, 184) #(204, 236, 255) #(147, 156, 167) # (93, 108, 111)
ALT_BG_COLOR_LIST = {
    "_(": BGCOLOR, # ( 200, 210, 240), #(255, 255, 255),
    "_)": BGCOLOR, # ( 180, 200, 230), #(255, 255, 255), # (200, 200, 170), 
    "_@": BGCOLOR, #( 160, 190, 220),
    "_*": (148, 148, 148), #(111, 184, 226), 
    "_&": (0, 184, 226), 
    "_#": (254, 230, 0),
}
ALT_BG_COLOR_IDS = "_(_)_@_*_&_#" 

def txt_commands_dat_convert(text):
# this function replaces special characters of command.dat, for example  "_(" by the right char code in the arcade TTF font.
# it also adds color codes, using minecraft standard, when a special char needs to be colored (ex: "§c" sets current color to red...)
    conversion_table = {
    # https://minecraft.fandom.com/wiki/Formatting_codes
        # icons from ./key1.bmp
        "_A" : "§0A§r",  # + chr(57355) +"§r" # button: A
        "_B" : "§0B§r", # button: B
        "_C" : "§0C§r", # button: C
        "_D" : "§0D§r", # button: D
        "_P" : "§0P§r", # button: punch
        "_K" : "§0K§r", # button: kick

        "_S" : "§0" + chr(57368) +"§r", # button: Taunt
        "^S" : "§0" + chr(57369) +"§r", # button: Select (AES)
        
        "_1" : chr(57359), # joy: down+left
        "_2" : chr(57360), # joy: down
        "_3" : chr(57361), # joy: down+right
        "_4" : chr(57353), # joy: left
        "_5" : "§c" + chr(57362) +"§r", # joy: center
        "_6" : chr(57354), # joy: right
        "_7" : chr(57363), # joy: up+left
        "_8" : chr(57364), # joy: up
        "_9" : chr(57365), # joy: up+right        
        "_+" : "+",
        "^1" : chr(57359)+".", # joy: down+left
        "^2" : chr(57360)+".", # joy: down
        "^3" : chr(57361)+".", # joy: down+right
        "^4" : chr(57353)+".", # joy: left
        "^6" : chr(57354)+".", # joy: right
        "^7" : chr(57363)+".", # joy: up+left
        "^8" : chr(57364)+".", # joy: up
        "^9" : chr(57365)+".", # joy: up+right  
        "^!" : chr(57367),     # special arrow (down right)   

        # icons from ./key2.bmp
        "_(": "§0"+chr(57392),
        "_)": "§8"+chr(57392)+"§r",
        "_@": "§8"+chr(57392)+"§r",
        "_*": "§0"+chr(57391),
        "_&": "§9"+chr(57391)+"§r",
        "_#": "§9"+chr(57391)+"§r",
        "(-)":"(-)",
        "(!)":"(!)",
        "_>" : chr(9670),
        "_<" : chr(9674),
        "_m" : chr(57349),
        "_^": "(air)", # AIR
        "_?": chr(57371), # DIR
        "_X": "[tap]", # tap
        "_`": chr(183), # middle dot centered
        "_O": chr(57370),

    }

    new_text = text

    for key in conversion_table:
        new_text = new_text.replace(key, conversion_table[key])
    
    return new_text

def render_coloured_text(x, y, image_draw, text, default_color, font, charspacing, align, wrapenabled = True):
    color_dict = {
    # source: https://minecraft.fandom.com/wiki/Formatting_codes
        "§0": (0, 0, 0), # black
        "§1": (0, 0, 170), # dark_blue
        "§2": (0, 170, 0), # dark_green
        "§3": (0, 170, 170), # dark_aqua
        "§4": (170, 0, 0), # dark_red
        "§5": (170, 0, 170), # dark_purple
        "§6": (255, 170, 0), # gold
        "§7": (170, 170, 170), # gray
        "§8": (85, 85, 85), # dark_gray
        "§9": (85, 85, 255), # blue
        "§a": (85, 255, 85), # green
        "§b": (85, 255, 255), # aqua
        "§c": (255, 85, 85), # red
        "§d": (255, 85, 255), # light_purple
        "§e": (255, 255, 85), # yellow
        "§f": (255, 255, 255), # white
        "§g": (221, 214, 5), # minecoin_gold
    }

    
    txtcolor = default_color
    x_pos = x
    nb_rows = 0

    #chec if wrapping is enabled. If not, cut the text if too long
    wrapped_text = []
    if wrapenabled:
        wrapped_text = textwrap.wrap(text, width=TEXT_WRAP_AT)
    else:
        if len(text.strip())>TEXT_WRAP_AT:
            wrapped_text.append(text[0:TEXT_WRAP_AT-1]+chr(57371)) # "..."
        else:
            wrapped_text.append(text.strip())

    #print(wrapped_text)
    for text_part in wrapped_text:
        for i in range(0,len(text_part)):
            if text_part[i] == '§':
                continue
            elif text_part[i-1] == '§':
                if text_part[i] in "01234567890abcdefg":
                    txtcolor = color_dict["§"+text_part[i]]
                if text_part[i] == 'r':
                    txtcolor = default_color 
                continue
            width, height = image_draw.textsize(text_part[i], font)
            x_pos += charspacing #width

            image_draw.text((x_pos, y + nb_rows * ROWS_SPACING), text_part[i], fill = txtcolor, font = font, align = align)
        x_pos = x + 2 * CHARSPACING
        nb_rows += 1
    
    return nb_rows

def command_block_img_gen(block: command_block):
    SIZEH    = 35
    FONTSIZE = 40
    TXTCOLOR = (255, 255, 255)
    BGCOLOR  = (53, 68, 81)
    LMARGIN  = 15
    HMARGIN  = 15
    IMGWIDTH = 1600
    CHARSPACING = 22

    im_height = 2*HMARGIN + SIZEH * len(block.block_rows)
    im = Image.new("RGBA", (IMGWIDTH, im_height), BGCOLOR)
    draw = ImageDraw.Draw(im)

    draw.rounded_rectangle([3, 3, IMGWIDTH-4 , im_height -3] , radius=3, fill=None, outline=TXTCOLOR, width=1)

    # there are many empty spaces chars on each line
    # ..let's find where we can start to remove them
    spaces_pos = 0
    for i in range(1, len(block.block_rows)):
        text = block.block_rows[i]
        spaces_pos_row = text.find("        ")
        if(spaces_pos_row > spaces_pos):spaces_pos=spaces_pos_row

    # Print title
    font = ImageFont.truetype(ARCADE_FONT, FONTSIZE)
    text = block.block_title
    text = text[0:spaces_pos+2] + text[spaces_pos+2:1000].replace("  ","")
    draw.text((LMARGIN, HMARGIN), text, fill = TXTCOLOR, font = font, align = 'left')
 
    # Print each line
    for i in range(1, len(block.block_rows)):
        text = block.block_rows[i]
        text = text[0:spaces_pos+2] + text[spaces_pos+2:1000].replace("  ","")
        text = txt_commands_dat_convert(text)

        render_coloured_text(x = LMARGIN, y = HMARGIN + SIZEH * i, image_draw = draw, text = text, default_color = TXTCOLOR, font = font, charspacing = CHARSPACING, align = 'left')

    #im.show()
    filename = './img-cache/cmd-block-'+ block.rom + '-' + str(block.num) +'.png'
    #print(filename)
    im.save(filename)

    return(filename)

def command_block_img_gen_v2(block: command_block):
    SIZEH    = ROWS_SPACING # 35
    FONTSIZE = 40
        
    # BGCOLOR2 = ( 200, 210, 240)
    LMARGIN  = 10
    HMARGIN  = 10
    IMGWIDTH = 1000
    TITLE_POST_SPACING = 35 # nb empty pixels to add after title.

    # rows types
    # - with spacer ==> to split in 2 lines. First will get special color.
    # - lines with header
    
    #determine image height from start
    h = 2
    for i in range(1, len(block.block_rows)):
        text = block.block_rows[i]
        if text.find("        ") == -1:
            h += len(textwrap.wrap(text, width=TEXT_WRAP_AT))
        elif len(text)>2:   
            h += len(textwrap.wrap(text, width=TEXT_WRAP_AT))
    im_height = round(2*HMARGIN + SIZEH * h + TITLE_POST_SPACING)
    #im_height = round(2*HMARGIN + SIZEH * 2.1 * len(block.block_rows))
    
    im = Image.new("RGBA", (IMGWIDTH, im_height))
    draw = ImageDraw.Draw(im)

    draw.rounded_rectangle([1, 1, IMGWIDTH-1 , (im_height -1)] , radius=18, fill=BGCOLOR, outline=TXTCOLOR, width=1)

    # there are many empty spaces chars on each line
    # ..let's find where we can start to remove them
    spaces_pos = 0
    for i in range(1, len(block.block_rows)):
        text = block.block_rows[i]
        spaces_pos_row = text.find("        ")
        if(spaces_pos_row > spaces_pos):spaces_pos=spaces_pos_row

    # Print title
    draw.rounded_rectangle([1, 1, IMGWIDTH-1 , (ROUNDED_RECT_RADIUS * 2)] , radius=ROUNDED_RECT_RADIUS, fill=HEADER_COLOR, outline=HEADER_COLOR, width=1)
    draw.rectangle([1, ROUNDED_RECT_RADIUS, IMGWIDTH-1 , HEADER_HEIGHT - ROUNDED_RECT_RADIUS ], fill=HEADER_COLOR, outline=HEADER_COLOR, width=1)
    font = ImageFont.truetype(ARCADE_FONT, FONTSIZE * 2)
    text = block.block_title
    text = text[0:spaces_pos+2] + text[spaces_pos+2:1000].replace("  ","")
    draw.text((LMARGIN, HMARGIN), text, fill = HEADER_TXT_COLOR, font = font, align = 'center')

    v_index = 1 # used to know where to write text on vertical axis
    # Print each line
    font = ImageFont.truetype(ARCADE_FONT, FONTSIZE)
    for i in range(1, len(block.block_rows)):
        text = block.block_rows[i]
        
        # determine row type
        if text.find("        ") == -1:
            row_type = 'basic'
        else:
            row_type = 'double'

        if row_type == 'basic':
            text = txt_commands_dat_convert(text)
        
            v_index += render_coloured_text(x = LMARGIN -4, y = HMARGIN + SIZEH *  v_index  + TITLE_POST_SPACING, image_draw = draw, text = text, default_color = (0, 0, 0), font = font, charspacing = CHARSPACING, align = 'left', wrapenabled=True)
            
            
        if row_type == 'double':
            text = text[0:spaces_pos+2] + text[spaces_pos+2:1000].replace("  ","")

            # in this design, each command.dat row is shown on 2 rows in the image

            #row 1 background
            draw.rectangle(xy = (1+4, HMARGIN + SIZEH *  v_index +TITLE_POST_SPACING, IMGWIDTH-1, HMARGIN + SIZEH *  v_index  + SIZEH + TITLE_POST_SPACING), fill = SUBHEADER_COLOR)

            #row 2 background
            rect_color = BGCOLOR
            if text[0:2] in ALT_BG_COLOR_IDS:
                rect_color = ALT_BG_COLOR_LIST[text[0:2]]
            draw.rectangle(xy = (1, HMARGIN + SIZEH *  v_index + SIZEH + TITLE_POST_SPACING, IMGWIDTH-1, HMARGIN + SIZEH *  v_index + 2 * SIZEH + TITLE_POST_SPACING), fill = rect_color)

            text = txt_commands_dat_convert(text)
        
            #row 1 text
            text1 = text[0:spaces_pos+2]
            render_coloured_text(x = LMARGIN-4, y = HMARGIN + SIZEH *  v_index  + TITLE_POST_SPACING, image_draw = draw, text = text1, default_color = TXTCOLOR, font = font, charspacing = CHARSPACING, align = 'left', wrapenabled=False)
        
            #row 2 text
            text2 = text[spaces_pos+2:1000].replace("  ","")
            v_index += 1 + render_coloured_text(x = LMARGIN+8, y = HMARGIN + SIZEH * (v_index + 1) + TITLE_POST_SPACING, image_draw = draw, text = text2, default_color = TXTCOLOR2, font = font, charspacing = CHARSPACING, align = 'left', wrapenabled=True)
            draw.line((0, HMARGIN + SIZEH *  v_index  + TITLE_POST_SPACING-2 , IMGWIDTH, HMARGIN + SIZEH *  v_index  + TITLE_POST_SPACING - 2), fill= (0,0,0), width=5 )

    # border
    draw.rounded_rectangle([1, 1, IMGWIDTH-1 , (im_height -1)] , radius=18, outline=TXTCOLOR, width=5)

    filename = './img-cache/cmd-block-'+ block.rom + '-' + str(block.num) +'.png'
    im.save(filename)

    return(filename)

def get_command_blocks(gamename, command_dat_filename):
    game_command_blocks = []
    block_files = []

    f = open(command_dat_filename, "r", encoding="UTF-8")    
    #search game in file
    found    = False
    finished = False
    i = 0
    rows = f.readlines()
    f.close()
    for row in rows:
        #if row announces a new game, and still not found
        i += 1
        
        if (not found) and (row[0:5] == "$info"):
            game_list=row[6:].split(",")
            #print(game_list)
            if (gamename in game_list)+((gamename+"\n") in game_list):
                found = True
                nb_blocks=0

        #game has been found, proceed with the commands
        if found:
            if row[0:4] == "$end":
                finished = True
            else:
                if nb_blocks == 0:
                    if ((row[0:1] == "-")+(row[0:1] == "—"))*(row[0:10].find("_")==-1)*(row[2:].find("-")>0): #new blocks start with "- " and should not have "_" near start of row and should have another "-"
                        nb_blocks += 1
                        block = command_block(gamename, row, nb_blocks)
                else:
                    if ((row[0:1] == "-")+(row[0:1] == "—"))*(row[0:10].find("_")==-1)*(row[2:].find("-")>0):
                        nb_blocks += 1
                        game_command_blocks.append(block)
                        block = command_block(gamename, row, nb_blocks)
                    else:
                        # some command.dat files contain weird things, maybe one day I will understand what this is about and convert those.
                        toclean= [u"(-/-/\u2500) ", u"(-/I/\u2500) ", "(-/-/O) ", "(-/I/O) ", "(!/I/O) "]
                        cleaned_row = row
                        for s in toclean:
                            cleaned_row = cleaned_row.replace(s, "")
                        if len(cleaned_row)>2:
                            block.block_rows.append(cleaned_row)

        if finished:
            break

    for b in game_command_blocks:
        #print(b.block_title[0:30]) #, end='')

        block_filename = command_block_img_gen_v2(b)
        block_files.append(block_filename)


    #print("number of blocks = "+str(len(game_command_blocks)))
    if found:
        return block_files
    else:
        return []


