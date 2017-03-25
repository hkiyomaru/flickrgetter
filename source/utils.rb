require 'fileutils'
require 'json'
require 'open-uri'

IMAGE_SAVE_DIR = '../download/images/'
INFO_SAVE_DIR  = '../download/meta/'
INFO_FILE = 'metainfo.json'


def validate desc, tags, min_desc_len=10, max_desc_len=140, min_tags_num=3
  # Reject images with too short descriptions or too long descriptions
  if desc.length < min_desc_len || desc.length > max_desc_len
    return false
  end
  # Reject images with too few tags
  if tags.length < min_tags_num
    return false
  end
  # Everything is well
  return true
end

def download_image(url)
  file_name = File.basename url
  save_dir = IMAGE_SAVE_DIR
  file_path = save_dir + file_name

  # Create directory if it does not exist
  FileUtils.mkdir_p(IMAGE_SAVE_DIR) unless FileTest.exist? IMAGE_SAVE_DIR

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

def save_metainfo meta_info
  file_name = INFO_FILE
  save_dir = INFO_SAVE_DIR
  file_path = save_dir + file_name

  # Create directory if it does not exist
  FileUtils.mkdir_p(INFO_SAVE_DIR) unless FileTest.exist? INFO_SAVE_DIR

  # Save downloaded image
  begin
    File.open(file_path, 'w') do |f|
      f.write(meta_info.to_json)
    end
  rescue
    return false # Failure
  end

  return true # Success
end

def make_object_list synset
  synset.gsub!(/, | /, "\n")  # split comma-separated values
  synset.downcase!  # downcase every character
  obj_list = synset.split('\n')  # make object list
  obj_list.uniq
  obj_list.reject(&:empty?)
end
