## Importing Necessary Modules
import requests # to get image from the web
import shutil # to save it locally

IMG_CACHE_FOLDER = 'img-cache/'

def download_image(url):
    # print("downloading " + url)
    image_url = url
    filename = image_url.split("/")[-1]
    # Open the url image, set stream to True, this will return the stream content.
    
    r = requests.get(image_url, stream = True)

    # Check if the image was retrieved successfully
    if r.status_code == 200:
        # Set decode_content value to True, otherwise the downloaded image file's size will be zero.
        r.raw.decode_content = True
    
        # Open a local file with wb ( write binary ) permission.
        with open(IMG_CACHE_FOLDER + filename,'wb') as f:
            shutil.copyfileobj(r.raw, f)
        # print("OK")
        return IMG_CACHE_FOLDER + filename
    
    else:
        print("Error downloading " + filename)
        return 0



