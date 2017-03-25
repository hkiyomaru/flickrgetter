require 'flickraw'
require 'yaml'

require './flickr_getter.rb'


# Settings
num_of_images = 10  # number of images you want to collect
per_page      = 100      # 100 - 500
min_desc_len  = 10
max_desc_len  = 140
min_tags_num  = 3
filtering_tag = true

# Flickr API
CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file(CONFIG_PATH)

FlickRaw.api_key       = config_data['key']
FlickRaw.shared_secret = config_data['secret']

# Run
runner = FlickrGetter.new(min_desc_len, max_desc_len, min_tags_num, filtering_tag)
while runner.num_of_images < num_of_images
  images = flickr.photos.getRecent(:per_page => per_page)
  runner.run(images)
end

# Dump side information
runner.save_metainfo
