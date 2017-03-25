require 'fileutils'
require 'json'
require 'open-uri'


IMAGE_SAVE_DIR = '../download/images/'
INFO_SAVE_DIR  = '../download/meta/'
INFO_FILE = 'metainfo.json'

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
