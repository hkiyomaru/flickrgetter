require 'flickraw'
require 'yaml'

require './utils.rb'


# Flickr API
CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file CONFIG_PATH

FlickRaw.api_key = config_data['key']
FlickRaw.shared_secret = config_data['secret']

images = flickr.photos.getRecent :per_page => 50
meta_info = []
ol = []

File.open('imagenet_synsets') do |f|
  synset = f.read
  ol = make_object_list synset
end

images.each do |image|
    title     = image.title
    info      = flickr.photos.getInfo :photo_id => image.id, :secret => image.secret
    desc      = info.description
    owner     = info.owner.username
    posted    = Time.at(info.dates.posted.to_i).to_s
    url       = FlickRaw.url image
    base_name = File.basename url
    tags      = Array(info.tags)

    puts "title: " + title
    puts "URL: "   + url
    puts ""

    _meta_info = {
      "url"   => url,
      "file"  => base_name,
      "owner" => owner,
      "date"  => posted,
      "title" => title,
      "desc"  => desc,
      "tags"  => tags,
    }

    # select tags correspond to objects
    tags = tags & ol

    # Save images and their side information
    if validate desc, tags
      meta_info.push _meta_info if download_image url
    end
end

# Dump side information
save_metainfo meta_info
