# Crawler program to collect Flickr images and their side information
require 'optparse'
require './crawler.rb'


# Option parser
options = {}
OptionParser.new do |opt|
    opt.on('-q QUERY', 'path to target query') {|v| options[:q] = v}
    opt.on('-n NUMBER', 'number of images per class') {|v| options[:n] = v}
    opt.parse!(ARGV)
end
QUERY_PATH = options[:q]
NUM_OF_IMAGES_PER_CLASS = options[:n].to_i

# Paths
IMAGE_SAVE_DIR = '../download/images/'
INFO_SAVE_DIR = '../download/meta/'
LOG_DIR = '../log/'
LOG_FILE_PATH = '../log/crawler.log'

# Restrinctions for collecting Flickr images
min_desc_len = 10
max_desc_len = 140
min_tags_num = 3
num_core = 4

# Flickr API Configuration
CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file(CONFIG_PATH)
FlickRaw.api_key = config_data['key']
FlickRaw.shared_secret = config_data['secret']

# Scrape Flickr images and their side information
Crawler.new(
    NUM_OF_IMAGES_PER_CLASS,
    min_desc_len,
    max_desc_len,
    min_tags_num,
    num_core,
    QUERY_PATH
).run
