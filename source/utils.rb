def make_object_list(synset_path)
  File.open(synset_path) do |f|
    synset = f.read
    synset.gsub!(/, | /, "\n")  # split comma-separated values
    synset.downcase!  # downcase every character
    obj_list = synset.split("\n")  # make object list
    obj_list.uniq
    obj_list.reject(&:empty?)
    return obj_list
  end
end

def append_hash_tags(tags, desc)
  _hash_tags = desc.scan(%r|\s?(#[^\s　]+)\s?|).flatten  # extract hash tags
  if _hash_tags.length > 0
    _hash_tags.map { |tag| tag.slice!(0)}  # remove #
  end
  tags = tags + _hash_tags
  tags.uniq
  return tags
end
