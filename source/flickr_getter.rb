require 'fileutils'
require 'json'
require 'open-uri'

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
    @meta_info     = []
    # Make object list from ImageNet synsets
    make_object_list
    # Create directory if it does not exist
    FileUtils.mkdir_p(IMAGE_SAVE_DIR) unless FileTest.exist? IMAGE_SAVE_DIR
    FileUtils.mkdir_p(INFO_SAVE_DIR)  unless FileTest.exist? INFO_SAVE_DIR
  end

  def run(images)
    images.each do |image|
        title     = image.title
        info      = flickr.photos.getInfo(:photo_id => image.id, :secret => image.secret)
        desc      = info.description
        owner     = info.owner.username
        posted    = Time.at(info.dates.posted.to_i).to_s
        url       = FlickRaw.url image
        base_name = File.basename(url)
        tags      = Array(info.tags)
        if @filtering_tag
          tags = tags & @obj_list  # select tags correspond to objects
        end

        puts "URL: " + url

        # Save images and their side information
        if validate(desc, tags)
          _meta_info = {
            "url"   => url,
            "file"  => base_name,
            "owner" => owner,
            "date"  => posted,
            "title" => title,
            "desc"  => desc,
            "tags"  => tags,
          }
          @meta_info.push _meta_info if download_image(url)
          @num_of_images += 1  # increment total number of images
        end
    end
  end

  def validate(desc, tags)
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

  def download_image(url)
    file_name = File.basename(url)
    save_dir = IMAGE_SAVE_DIR
    file_path = save_dir + file_name

    # Save downloaded image
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

  def save_metainfo
    save_dir = INFO_SAVE_DIR
    file_path = save_dir + 'metainfo.json'

    # Save downloaded image
    begin
      File.open(file_path, 'w') do |f|
        f.write(@meta_info.to_json)
      end
    rescue
      return false # Failure
    end

    return true # Success
  end

  def make_object_list
    File.open(IMAGENET_SYNSET_PATH) do |f|
      synset = f.read
      synset.gsub!(/, | /, "\n")  # split comma-separated values
      synset.downcase!  # downcase every character
      obj_list = synset.split("\n")  # make object list
      obj_list.uniq
      obj_list.reject(&:empty?)
      @obj_list = obj_list
    end
  end
end
