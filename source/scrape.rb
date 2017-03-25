require 'flickraw'
require 'yaml'

CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file CONFIG_PATH

FlickRaw.api_key = config_data['key']
FlickRaw.shared_secret = config_data['secret']

images = flickr.photos.getRecent

images.each do |image|
    info = flickr.photos.getInfo :photo_id => image.id, :secret => image.secret
    sizes = flickr.photos.getSizes :photo_id => image.id
    size_list = sizes.map{ |size| "(#{ size.width } : #{ size.height })"}.join(", ")
    posted = Time.at(info.dates.posted.to_i).to_s
    url = FlickRaw.url image
    tags = info.tags
    tag_list = tags.map{ |tag| "#{ tag }" }.join(", ")

    puts "title: "       + image.title
    puts "URL: "         + url
    puts "Owner: "       + info.owner.username
    puts "Date: : "      + posted
    puts "Size: "        + size_list
    puts "Description: " + info.description
    puts "Tags: :"       + tag_list
    puts ""
end
