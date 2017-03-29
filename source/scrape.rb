# Crawler program to collect Flickr images and their side information
require './crawler.rb'


# Paths
IMAGE_SAVE_DIR       = '../download/images/'
INFO_SAVE_DIR        = '../download/meta/'
IMAGENET_SYNSET_PATH = './imagenet_synsets'

# Settings for collecting Flickr images
num_of_images_per_class = 10
min_desc_len = 10
max_desc_len = 140

# Flickr API
CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file(CONFIG_PATH)
FlickRaw.api_key = config_data['key']
FlickRaw.shared_secret = config_data['secret']

# Scrape Flickr images and their side information
runner = Crawler.new(num_of_images_per_class, min_desc_len, max_desc_len)
runner.run
