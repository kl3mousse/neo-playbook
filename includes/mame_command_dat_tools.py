#from fileinput import filename
from PIL import Image, ImageDraw, ImageFont

class command_block:
    def __init__(self, rom, title, num):
        self.rom              = rom
        self.block_title      = title
        self.num              = num
        self.block_rows       = []
        # print("**** "+rom+" * "+title)

def txt_commands_dat_convert(text):
# this function replaces special characters of command.dat, for example  "_(" by the right char code in the arcade.ttf font.
# it also adds color codes, using minecraft standard, when a special char needs to be colored (ex: "§c" sets current color to red...)
    conversion_table = {
    # https://minecraft.fandom.com/wiki/Formatting_codes
        # icons from ./key1.bmp
        "_A" : "§c" +"A§r",  # + chr(57355) +"§r" # button: A
        "_B" : "§6" + chr(57356) +"§r", # button: B
        "_C" : "§a" + chr(57357) +"§r", # button: C
        "_D" : "§b" + chr(57358) +"§r", # button: D
        "_P" : "§d" + chr(57366) +"§r", # button: punch
        "_K" : "§5" + chr(57367) +"§r", # button: kick

        "_S" : "§c" + chr(57368) +"§r", # button: Taunt
        "^S" : "§6" + chr(57369) +"§r", # button: Select (AES)
        
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

        "^1" : chr(57372), # joy: down+left+dot
        "^2" : chr(57373), # joy: down+left+dot

        # icons from ./key2.bmp
        "_(": chr(8226),
        "_)": "2",
        "_@": "§93§r",
        "_*": chr(57344),
        "_&": "§c5§r",
        "_#": "6",
        "(-)":"(-)",
        "(!)":"(!)",
        "_>" : chr(9670),
        "_<" : chr(9674),
        "_m" : chr(57349),
        "_^": chr(57370), # AIR
        "_?": chr(57371), # DIR

    }

    new_text = text

    for key in conversion_table:
        new_text = new_text.replace(key, conversion_table[key])
    
    return new_text

def render_coloured_text(x, y, image_draw, text, default_color, font, charspacing, align):
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

    x_pos = x
    txtcolor = default_color

    for i in range(0,len(text)):
        if text[i] == '§':
            continue
        elif text[i-1] == '§':
            if text[i] in "01234567890abcdefg":
                txtcolor = color_dict["§"+text[i]]
            if text[i] == 'r':
                txtcolor = default_color 
            continue
        width, height = image_draw.textsize(text[i], font)
        x_pos += charspacing #width

        image_draw.text((x_pos, y), text[i], fill = txtcolor, font = font, align = align)
    
    return 1


def command_block_img_gen(block: command_block):
    SIZEH    = 20
    FONTSIZE = 24
    TXTCOLOR = (255, 255, 255)
    BGCOLOR  = (0, 0, 0)
    LMARGIN  = 5
    HMARGIN  = 5
    IMGWIDTH = 820
    CHARSPACING = 12
    
    SIZEH    = 35
    FONTSIZE = 40
    TXTCOLOR = (255, 255, 255)
    BGCOLOR  = (0, 0, 0)
    LMARGIN  = 15
    HMARGIN  = 15
    IMGWIDTH = 1600
    CHARSPACING = 22

    im = Image.new("RGBA", (IMGWIDTH, 2*HMARGIN + SIZEH * len(block.block_rows)), BGCOLOR)
    draw = ImageDraw.Draw(im)

    # there are many empty spaces chars on each line
    # ..let's find where we can start to remove them
    spaces_pos = 0
    for i in range(1, len(block.block_rows)):
        text = block.block_rows[i]
        spaces_pos_row = text.find("        ")
        if(spaces_pos_row > spaces_pos):spaces_pos=spaces_pos_row

    # Print title
    font = ImageFont.truetype('./fonts/AnonymousPro-Regular-arcade-controls.ttf', FONTSIZE)
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


def get_command_blocks(gamename, command_dat_filename):
    game_command_blocks = []
    block_files = []

    f = open(command_dat_filename, "r")    
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
            
            if gamename in game_list:
                found = True
                nb_blocks=0

        #game has been found, proceed with the commands
        if found:
            if row[0:4] == "$end":
                finished = True
            else:
                if nb_blocks == 0:
                    if (row[0:2] == "- ")*(row[0:10].find("_")==-1): #new blocks start with "- " and should not have "_" near start of row
                        nb_blocks += 1
                        block = command_block(gamename, row, nb_blocks)
                else:
                    if (row[0:2] == "- ")*(row[0:10].find("_")==-1):
                        nb_blocks += 1
                        game_command_blocks.append(block)
                        block = command_block(gamename, row, nb_blocks)
                    else:
                        block.block_rows.append(row)

        if finished:
            break

    for b in game_command_blocks:
        #print(b.block_title[0:30]) #, end='')

#        if (b.block_title[0:13] == "- BLUE MARY -") :
#        if (b.block_title[0:13] ==  "- TERRY BOGAR") :
#            block_filename = command_block_img_gen(b)

        block_filename = command_block_img_gen(b)
        block_files.append(block_filename)


    #print("number of blocks = "+str(len(game_command_blocks)))
    if found:
        return block_files
    else:
        return []

#get_command_blocks("kof2000", "./command-dat/command.dat")
#get_command_blocks("kof99", "./command-dat/command.dat")