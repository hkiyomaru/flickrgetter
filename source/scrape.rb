require 'flickraw'
require 'yaml'

require './flickr_getter.rb'


# Settings for collecting Flickr images
num_of_images = 10
per_page      = 10
min_desc_len  = 10
max_desc_len  = 140
min_tags_num  = 3

# Flickr API
CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file(CONFIG_PATH)
FlickRaw.api_key       = config_data['key']
FlickRaw.shared_secret = config_data['secret']

# Scrape Flickr images and their side information
runner = FlickrGetter.new(min_desc_len, max_desc_len, min_tags_num)
while runner.num_of_images < num_of_images
  images = flickr.photos.getRecent(:per_page => per_page)
  runner.run(images)
end

if runner.terminate?
  puts 'Success.'
else
  puts 'Failure.'
end
