class FileCsv
  def row_to_es(headers, row)
    doc = {}
    test = 
    doc["identifier"] = row["Filename"].gsub(".jpg","") if row["Title#1"]
    doc["title"] = !row["Title#1"].empty? ? row["Title#1"] : "No Title"
    doc["creator"] = row["Artist/Creator#1"] if row["Artist/Creator#1"]
    doc["description"] = row["Description#1"] if row["Description#1"]
    doc["format"] = row["Format#1"] if row["Format#1"]
    doc["source"] = row["Source#1"] if row["Source#1"]
    doc
end
end

# Fields from CSV and status 

# DONE        Filename          id  remove .jpg for id
# IGNORE      Identifier        not sure what this is being used for - perhaps relating docs? Ignore for now
# DONE        Title#1           ? Do we need to add sort?   title Sometimes blank
# DONE        Artist/Creator#1  creator    Usually blank
# TODO        Subject#1         most of these seem to be people. Index into people and see what happens
#             Subject#1$1 
#             Subject#1$3 
#             Subject#1$2 
#             Subject#1$5 
#             Subject#1$4 
#             Subject#1$7 
#             Subject#1$6 
# DONE        Description#1     description 
# TODO        Date#1            these are in weird format - 6/20/46 or 1947 - will need to regularize
# TODO        Format#1          format  examples   Photograph (recto) Cardboard frame (verso) might want to set all as "photographs"
# DONE        Source#1          source 
# DISCUSS     Language#1        eng or N/A - not entirely useful
# TODO        Relation#1        points to 1 other file to relate to. Need to make a field for this
# TODO        Coverage#1        I don't knwo how to add a nested field -kmd place (do we have dc:coverage?)
