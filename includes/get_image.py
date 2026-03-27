## Importing Necessary Modules
import requests # to get image from the web
import shutil # to save it locally
import os

IMG_CACHE_FOLDER = 'img-cache/'

def download_image(url):
    image_url = url
    filename = image_url.split("/")[-1]
    cached_path = IMG_CACHE_FOLDER + filename

    # Use cached version if available
    if os.path.exists(cached_path):
        return cached_path

    try:
        r = requests.get(image_url, stream = True, timeout=15)
    except requests.exceptions.RequestException:
        print("Error downloading " + filename)
        return None

    # Check if the image was retrieved successfully
    if r.status_code == 200:
        # Set decode_content value to True, otherwise the downloaded image file's size will be zero.
        r.raw.decode_content = True
    
        # Open a local file with wb ( write binary ) permission.
        with open(cached_path,'wb') as f:
            shutil.copyfileobj(r.raw, f)
        return cached_path
    
    else:
        print("Error downloading " + filename)
        return None



