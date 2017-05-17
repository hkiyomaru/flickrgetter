# Crawler Class: Collect Flickr images for each class
require 'date'
require 'fileutils'
require 'flickraw'
require 'json'
require 'logger'
require 'open-uri'
require 'parallel'
require 'pry'
require 'whatlanguage'
require 'yaml'


class Crawler
    def initialize(num_of_images_per_class, min_desc_len, max_desc_len,
                   min_tags_num, num_core, obj_path)
        @num_of_images_per_class = num_of_images_per_class
        @min_desc_len = min_desc_len
        @max_desc_len = max_desc_len
        @min_tags_num = min_tags_num
        @obj_lists, @obj_mask = make_object_lists(obj_path)

        # Create directory if it does not exist
        FileUtils.mkdir_p(IMAGE_SAVE_DIR) unless FileTest.exist?(IMAGE_SAVE_DIR)
        FileUtils.mkdir_p(INFO_SAVE_DIR) unless FileTest.exist?(INFO_SAVE_DIR)
        FileUtils.mkdir_p(LOG_DIR) unless FileTest.exist?(LOG_DIR)

        # hash for saving meta data
        @meta_info = {}

        # language detector
        @lang_detector = WhatLanguage.new(:all)

        # logger which writes log output to STDOUT as well as file
        @log = Logger.new("| tee -a #{LOG_FILE_PATH}")

        # progress
        @total = @meta_info.length

        # parallel
        @num_core = num_core

        # report initializing information
        @log.info("Target queries: #{ obj_path }")
        @log.info("Minimum length of descriptions: #{ @min_desc_len }")
        @log.info("Maximum length of descriptions: #{ @max_desc_len }")
        @log.info("Minimum number of tags: #{ @min_tags_num }")
        @log.info("Crawer has been initialized correctly.")
    end

    def run
        # run subprocesses
        sub_obj_list_size = @obj_lists.length / @num_core
        @obj_lists = @obj_lists.each_slice(sub_obj_list_size).to_a
        results = Parallel.map(@obj_lists, in_process: @num_core) do |sub_obj_lists|
            run_subprocess(sub_obj_lists)
        end

        # merge results
        results.each do |result|
            @meta_info.update(result)
        end

        # save meta information
        if done?
            @log.info('Done.')
        end
    end

    def run_subprocess(sub_obj_lists)
        sub_obj_lists.each do |obj_list|
            accept = 0
            last_update = nil

            while accept < @num_of_images_per_class
                begin
                    images = flickr.photos.search(
                                 :tags => obj_list,
                                 :max_upload_date => last_update,
                                 :per_page => 500,
                             )
                rescue
                    @log.error('Failed to open TCP connection to Flickr API.')
                    sleep(300)
                    next
                end
                _accept, _last_update = inspect(images)
                if _last_update == last_update
                    @log.info("There are no unsearched images about #{obj_list.join(', ')} anymore.")
                    break
                else
                    accept += _accept
                    last_update = _last_update
                    report_progress
                end
            end
        end

        return @meta_info
    end

    def inspect(images)
        accept = 0
        last_update = nil

        images.each do |image|
            # Get information
            image_id = image.id
            secret = image.secret
            begin
                info = flickr.photos.getInfo(:photo_id => image_id, :secret => secret)
                title = image.title
                desc = info.description
                owner = info.owner.username
                posted = Time.at(info.dates.posted.to_i).to_s
                url = FlickRaw.url(image)
                base_name = File.basename(url)
                tags = info.tags.map{ |tag| "#{ tag }"}
            rescue
                @log.error('Failed to get information of a image.')
                next
            end
            # Save image and its side information
            if eligible?(desc, tags)
                _meta_info = {
                    "secret" => secret,
                    "url"        => url,
                    "file"     => base_name,
                    "owner"    => owner,
                    "date"     => posted,
                    "title"    => title,
                    "desc"     => desc,
                    "tags"     => tags
                }
                if download_image?(url)
                    @meta_info.store(image_id, _meta_info)
                    accept += 1
                    @log.info(_meta_info.to_s)
                    break if accept == @num_of_images_per_class
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

    def eligible?(desc, tags)
        # Reject images with too short descriptions or too long descriptions
        if desc.length < @min_desc_len || desc.length > @max_desc_len
            return false
        end

        # Reject images with too few objects
        if tags.length < @min_tags_num
            return false
        end

        # Reject images without English descriptions
        if @lang_detector.language(desc) != :english
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
            @log.error('Failed to download and save a image.')
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
            @log.error('Failed to save meta data. Enter debug mode.')
            binding.pry  # Debug mode
            return false
        end

        return true
    end

    def make_object_lists(synset_path)
        obj_lists = []
        obj_mask = []

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

        obj_mask = obj_lists.flatten

        return obj_lists, obj_mask
    end

    def report_progress
        @log.info('Number of saved images: ' + @meta_info.length.to_s)
    end
end
