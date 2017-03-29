# Crawler Class: Collect Flickr images for each class
require 'date'
require 'fileutils'
require 'flickraw'
require 'json'
require 'open-uri'
require 'pry'
require 'yaml'


class Crawler
  def initialize(num_of_images_per_class, min_desc_len, max_desc_len)
    @num_of_images_per_class = num_of_images_per_class
    @per_page = [@num_of_images_per_class, 500].min
    @min_desc_len = min_desc_len
    @max_desc_len = max_desc_len
    @obj_lists = make_object_lists(IMAGENET_SYNSET_PATH)
    # Create directory if it does not exist
    FileUtils.mkdir_p(IMAGE_SAVE_DIR) unless FileTest.exist?(IMAGE_SAVE_DIR)
    FileUtils.mkdir_p(INFO_SAVE_DIR)  unless FileTest.exist?(INFO_SAVE_DIR)
    # hash for saving meta data
    @meta_info = {}
  end

  def run
    @obj_lists.each_with_index do |obj_list, index|
      puts 'Class:' + index.to_s
      num_of_images_per_class = 0
      last_update = nil
      while num_of_images_per_class < @num_of_images_per_class
        images = flickr.photos.search(
                  :tags            => obj_list,
                  :per_page        => @per_page,
                  :max_upload_date => last_update
                )
        accept, last_update = inspect(images, index)
        num_of_images_per_class += accept
      end
    end
    puts 'Everything went well.' if done?
  end

  def inspect(images, index)
    accept = 0  # number of saved images
    last_update = nil
    images.each do |image|
      # Get information
      image_id = image.id
      secret = image.secret
      begin
        info = flickr.photos.getInfo(:photo_id => image_id, :secret => secret)
      rescue
        next
      end
      title = image.title
      desc = info.description
      owner = info.owner.username
      posted = Time.at(info.dates.posted.to_i).to_s
      url = FlickRaw.url(image)
      base_name = File.basename(url)
      tags = Array(info.tags)
      puts posted
      # Save image and its side information
      if eligible?(desc)
        _meta_info = {
          "secret" => secret,
          "url"    => url,
          "file"   => base_name,
          "owner"  => owner,
          "date"   => posted,
          "title"  => title,
          "desc"   => desc,
          "tags"   => tags,
          "class"  => index
        }
        if download_image?(url)
          @meta_info.store(image_id, _meta_info)
          accept += 1
        end
      end
      # Update `last_update` value
      if last_update.nil?
        last_update = posted
      else
        last_update = [posted, last_update].min
      end
    end
    return accept, last_update
  end

  def eligible?(desc)
    # Reject images with too short descriptions or too long descriptions
    if desc.length < @min_desc_len || desc.length > @max_desc_len
      return false
    end
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
      return false
    end
    return true
  end

  def done?
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
    return true
  end

  def make_object_lists(synset_path)
    obj_lists = []
    File.open(synset_path) do |f|
      synsets = f.read
      synsets.downcase!
      synsets = synsets.split("\n")  # -> 1000 classes
      synsets.each do |synset|
        synset = synset.split(", ")
        synset.each do |element|
          element.gsub!(/ |-/, " " => "", "-" => "")  # eliminate space
        end
        obj_lists.push(synset)
      end
    end
    return obj_lists
  end
end