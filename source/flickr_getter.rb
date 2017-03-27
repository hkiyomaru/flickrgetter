require 'fileutils'
require 'json'
require 'open-uri'
require 'pry'

require './utils.rb'


IMAGE_SAVE_DIR       = '../download/images/'
INFO_SAVE_DIR        = '../download/meta/'
IMAGENET_SYNSET_PATH = './imagenet_synsets'


class FlickrGetter
  attr_accessor :num_of_images
  def initialize(min_desc_len, max_desc_len, min_tags_num, filtering_tag)
    @num_of_images = 0
    @min_desc_len  = min_desc_len
    @max_desc_len  = max_desc_len
    @min_tags_num  = min_tags_num
    @filtering_tag = filtering_tag
    @meta_info     = {}
    # Make object list from ImageNet synsets
    @obj_list = make_object_list(IMAGENET_SYNSET_PATH)
    # Create directory if it does not exist
    FileUtils.mkdir_p(IMAGE_SAVE_DIR) unless FileTest.exist? IMAGE_SAVE_DIR
    FileUtils.mkdir_p(INFO_SAVE_DIR)  unless FileTest.exist? INFO_SAVE_DIR
  end

  def run(images)
    images.each do |image|
        image_id  = image.id
        secret    = image.secret
        title     = image.title
        info      = flickr.photos.getInfo(:photo_id => image_id, :secret => secret)
        desc      = info.description
        owner     = info.owner.username
        posted    = Time.at(info.dates.posted.to_i).to_s
        url       = FlickRaw.url image
        base_name = File.basename(url)
        tags      = Array(info.tags)
        tags      = append_hash_tags(tags, desc)
        if @filtering_tag
          tags = tags & @obj_list  # select tags correspond to objects
        end

        # Save images and their side information
        if eligible?(desc, tags)
          _meta_info = {
            "secret" => secret,
            "url"    => url,
            "file"   => base_name,
            "owner"  => owner,
            "date"   => posted,
            "title"  => title,
            "desc"   => desc,
            "tags"   => tags,
          }
          @meta_info.store(image_id, _meta_info) if download_image?(url)
          @num_of_images += 1  # increment total number of images
          puts '#Progress: ' + @num_of_images
        end
    end
  end

  def eligible?(desc, tags)
    # Reject images with too short descriptions or too long descriptions
    if desc.length < @min_desc_len || desc.length > @max_desc_len
      return false
    end
    # Reject images with too few tags
    if tags.length < @min_tags_num
      return false
    end
    # Everything is well
    return true
  end

  def download_image?(url)
    file_name = File.basename(url)
    save_dir = IMAGE_SAVE_DIR
    file_path = save_dir + file_name
    begin
      open(file_path, 'wb') do |f|
        open(url) do |d|
          f.write(d.read)
        end
      end
    rescue
      return false # Failure
    end
    return true # Success
  end

  def terminate?
    save_dir = INFO_SAVE_DIR
    file_path = save_dir + 'metainfo.json'
    begin
      File.open(file_path, 'w') do |f|
        f.write(@meta_info.to_json)
      end
    rescue
      binding.pry   # Enter debug mode
      return false
    end
    return true  # Success
  end
end
