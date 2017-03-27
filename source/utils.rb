def make_object_list(synset_path)
  obj_list = []
  File.open(synset_path) do |f|
    synsets = f.read
    synsets.downcase!
    synsets.gsub!(/, /, "\n")  # split with comma
    synsets = synsets.split("\n")
    synsets.each do |synset|
      if synset.include?(" ")
        synset = synset.split(" ")
        obj_list.push(synset[-1])       # add noun
        obj_list.push(synset.join(""))  # add adjective + noun with no space
      else
        obj_list.push(synset)           # add noun
      end
    end
    # clean up object list
    obj_list.uniq!
    obj_list.reject!(&:empty?)
    return obj_list
  end
end

def append_hash_tags(tags, desc)
  _hash_tags = desc.scan(%r|\s?(#[^\s　]+)\s?|).flatten  # extract hash tags
  if _hash_tags.length > 0
    _hash_tags.map { |tag| tag.slice!(0)}  # remove #
  end
  tags = tags + _hash_tags
  tags.uniq!
  return tags
end
