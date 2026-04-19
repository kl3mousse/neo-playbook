from includes.mame_command_dat_tools import get_command_blocks
from PIL import Image, ImageDraw, ImageFont

command_files = get_command_blocks("kof2000", "./command-dat/command.dat")

if len(command_files)>0:
    print("Moves lists found in rom :" + str(len(command_files)) + " command blocks. " , end = '')
    filepath = command_files[1]
    im = Image.open(filepath)
    im.show()

    filepath = command_files[2]
    im = Image.open(filepath)
    im.show()

    filepath = command_files[3]
    im = Image.open(filepath)
    im.show()

    filepath = command_files[4]
    im = Image.open(filepath)
    im.show()