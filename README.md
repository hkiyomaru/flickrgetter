# Flickr Getter

This program provides Flickr images and corresponding side information (e.g., tags and descriptions).
You can filter out the tags which do not correspond to objects.
Also you can set restrictions on length of the descriptions.

## Environment

* OS: macOS Sierra
* Lang: Ruby 2.3.3
* Lib: flickraw 0.9.9

## Getting Started

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
