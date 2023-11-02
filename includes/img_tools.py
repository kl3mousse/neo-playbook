# ./includes/img_tools.py

#import cv2
from PIL import Image, ImageDraw, ImageEnhance

def clean_JPG(filename):
# this function simply opens a local Picture and save it with no change.
# This is used to fix some of the pictures from IGDB that have incorrect JPEG markers, and used to make FPDF crash.
#    img = cv2.imread(filename)
#    cv2.imwrite(filename, img)
    im = Image.open(filename)
    png_filename = filename[0:len(filename)-4]+".png"
    #print(filename + ">>>" + png_filename)
    im.save(png_filename, format='png')
    return png_filename

def getImgAspectRatio(filename):
    im = Image.open(filename)
    width, height = im.size
    img_ratio = width / height
    return img_ratio

def getImgSize(filename):
    im = Image.open(filename)
    width, height = im.size
    return width, height

def crop_bottomright(filename, ratio):
    im = Image.open(filename)
    width, height = im.size
    #print("##### cropping "+filename)
    prev_ratio = getImgAspectRatio(filename)
    if ratio > prev_ratio:
        #crop bottom
        new_bottom = round(width / ratio)
        im = im.crop((0, 0, width, new_bottom))
        #print("before: "+str(width)+"x"+str(height)+" /after: "+str(width)+"x"+str(new_bottom))
    else:
        #crop right
        new_right = round(height * ratio)
        im = im.crop((0, 0, new_right, height))
        #print("before: "+str(width)+"x"+str(height)+" /after: "+str(new_right)+"x"+str(height))
    im.save(filename)

def crop_upright(filename, ratio, vshift):
    im = Image.open(filename)
    width, height = im.size
    if vshift is None: vshift = 0
    #print("##### cropping "+filename)
    prev_ratio = getImgAspectRatio(filename)
    if ratio > prev_ratio:
        #crop bottom
        new_bottom = round(width / ratio)
        im = im.crop((0, height - new_bottom - vshift, width, height - vshift))
        #print("before: "+str(width)+"x"+str(height)+" /after: "+str(width)+"x"+str(new_bottom))
    else:
        #crop right
        new_right = round(height * ratio)
        im = im.crop((0, 0, new_right, height))
        #print("before: "+str(width)+"x"+str(height)+" /after: "+str(new_right)+"x"+str(height))
    im.save(filename)

def add_scanlines(filename):
    im1 = Image.open(filename).convert("RGBA")
    
    #creation of mask with scanlines
    im_mask = Image.new("L", im1.size, 0)
    draw = ImageDraw.Draw(im_mask)

    skip=False
    for y in range (0, im_mask.size[1]):
        if not skip:
            draw.line((0,y,im_mask.size[0],y),fill=128)
        skip = not skip

    #creation of a darker version of the image
    im2 = im1.copy()
    factor = 0.2 #darkens the image
    enhancer = ImageEnhance.Brightness(im2)
    im2 = enhancer.enhance(factor)

    out = Image.composite(im2, im1, im_mask)
    out.save(filename)

def footer_effect(filename, bg_color):
    im1 = Image.open(filename).convert("RGBA")
    
    im_mask = Image.new("L", im1.size, 0)
    draw = ImageDraw.Draw(im_mask)
    for y in range (0, im_mask.size[1]):
            draw.line((0,y,im_mask.size[0],y),fill=max(0, 255-4*y))

    im2 = Image.new("RGB", im1.size, bg_color)

    out = Image.composite(im2, im1, im_mask)
    #out.show()
    out.save(filename)

def image_resize(filename, target_width):
    """
    Resizes an image to the specified width while maintaining the aspect ratio.
    
    Args:
    - filename (str): The path to the image file.
    - target_width (int): The desired width for the resized image.
    
    Returns:
    - str: The path to the resized image.
    """

    im = Image.open(filename)
    aspect_ratio = im.width / im.height    
    new_height = int(target_width / aspect_ratio)
    resized_im = im.resize((target_width, new_height))
    
    resized_im.save(filename)
    
    return filename
