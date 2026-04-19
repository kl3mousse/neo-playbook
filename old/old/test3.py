from PIL import Image, ImageDraw, ImageEnhance
from includes.img_tools import footer_effect, clean_JPG, crop_bottomright, add_scanlines
from includes.get_image import download_image

filename = 'https://www.fgbg.art/static/kof2k3-china2-fec9768e1ea49bffadf973ed542acbff.png'

pic = download_image(filename)
filename=clean_JPG(pic)

crop_bottomright(pic, 210 / 40)
add_scanlines(pic)
#footer_effect(filename)

add_scanlines('img/icons/placeholder-yellow.png')