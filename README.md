# Flickr Getter

This program provides Flickr images and corresponding side information (e.g., tags and descriptions).
You can filter out the tags which do not correspond to objects.
Also you can place restrictions on length of the descriptions.

## Development Environment

* OS       : macOS Sierra
* Language : Ruby 2.3.3

## Getting Started

First of all, you have to get an API key of Flickr.

[The Flickr Developer Guide: API](https://www.flickr.com/services/developer/api/)

Referring to config/secrets.yml.example, you can make Flickr API available by creating config/secrets.yml.

Then, install dependent libraries.

```
$ gem install bundler
$ bundle install --path vendor/bundle
```

## Run

```
$ cd source/
$ bundle exec ruby scrape.rb
```

Everything will be saved at `download` directory.

## Change restrictions

* num_of_images (int): number of images you want to collect at least
* per_page (int): number of images you'll get with one request
* min_desc_len (int): minimum length of descriptions
* max_desc_len (int): maximum length of descriptions
* min_tags_num (int): minimum number of tags
