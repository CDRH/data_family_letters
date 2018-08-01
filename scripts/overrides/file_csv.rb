class FileCsv

  def row_to_es(headers, row)
    doc = {}
    # there must be an id for this row
    if row["Filename"]
      id = row["Filename"].gsub(".jpg", "") if present?(row["Filename"])
      doc["id"] = id
      # doc["category"]
      doc["collection"] = @options["es_type"]
      doc["collection_desc"] = @options["collection_desc"] || @options["es_type"]
      # doc["contributor"]
      doc["creator"] = { "name" => row["Artist/Creator#1"] } if present?(row["Artist/Creator#1"])
      doc["data_type"] = "csv"
      # doc["date"]
      # doc["date_display"]
      doc["description"] = row["Description#1"] if present?(row["Description#1"])
      doc["format"] = row["Format#1"] if present?(row["Format#1"])
      doc["identifier"] = id
      # TODO this size should probably come out of the config file
      doc["image_id"] = "#{@options["media_base"]}#{id}.jpg/full/!150,150/0/default.jpg"
      # doc["keywords"]
      # doc["language"]
      # doc["languages"]
      doc["medium"] = row["Format#1"] if present?(row["Format#1"])
      # doc["person"]
      # doc["people"]
      # doc["places"]
      # doc["publisher"]
      # doc["recipient"]
      # doc["rights"]
      # doc["rights_holder"]
      # doc["rights_uri"]
      doc["source"] = row["Source#1"] if present?(row["Source#1"])
      # doc["subjects"]
      # doc["subcategory"]
      doc["text"] = row["Description#1"] if present?(row["Description#1"])
      doc["title"] = present?(row["Title#1"]) ? row["Title#1"] : "No Title"
      # doc["title_sort"]
      # doc["topics"]
      # doc["uri"]
      # filename in uri_data is coming from the filename of the CSV file, NOT the "Filename" column
      doc["uri_data"] = "#{@options["data_base"]}/data/#{@options["collection"]}/csv/#{filename}"
      # doc["uri_html"]
      # doc["works"]
    end
    doc
  end

  def build_html_from_csv
    @csv.each do |row|
      next if row.header_row?

      id = row["Filename"].gsub(".jpg", "") if row["Filename"]
      # using XML instead of HTML for simplicity's sake
      builder = Nokogiri::XML::Builder.new do |xml|o
        xml.div(class: "main_content") {
          xml.image( src: "#{@options["media_base"]}#{id}.jpg/full/full/0/default.jpg" )
          xml.p(row["Description#1"], class: "image_description")
        }
      end
      write_html_to_file(builder, id)
    end
  end

end

# Fields from CSV and status with API ES index

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
