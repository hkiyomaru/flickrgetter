require 'flickraw'
require 'yaml'

require './utils.rb'

CONFIG_PATH = '../config/secrets.yml'
config_data = YAML.load_file CONFIG_PATH

FlickRaw.api_key = config_data['key']
FlickRaw.shared_secret = config_data['secret']

images = flickr.photos.getRecent :per_page => 1
meta_info = []

images.each do |image|
    title     = image.title
    info      = flickr.photos.getInfo :photo_id => image.id, :secret => image.secret
    desc      = info.description
    owner     = info.owner.username
    posted    = Time.at(info.dates.posted.to_i).to_s
    url       = FlickRaw.url image
    base_name = File.basename url
    tags      = Array(info.tags)

    puts "title: "       + title
    puts "URL: "         + url
    puts "Owner: "       + owner
    puts "Date: : "      + posted
    puts "Description: " + desc
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

    # Save images and their side information
    meta_info.push _meta_info if download_image url
end

save_metainfo meta_info
