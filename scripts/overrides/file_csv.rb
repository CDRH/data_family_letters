class FileCsv

  def build_html_from_csv
    @csv.each do |row|
      next if row.header_row?

      id = row["Filename"].gsub(".jpg", "") if row["Filename"]
      # using XML instead of HTML for simplicity's sake
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.div(class: "main_content") {
          xml.image( src: "#{@options["media_base"]}#{id}.jpg/full/full/0/default.jpg" )
          xml.p(row["Description#1"], class: "image_description")
        }
      end
      write_html_to_file(builder, id)
    end
  end

  # returns the data from either the first page or combines into one text field
  # flags any discrepancies if they are not to be combined
  def data_from_pages(pages, field, combine: false)
    data = pages.map { |p| CommonXml.normalize_space(p[field]) if present?(p[field]) }
    data = data.compact.uniq
    if combine
      # returns an array if combine is requested
      data
    elsif data.length <= 1
      # return a string if combine was not requested
      data.first
    else
      warning = <<-WARNING
        Pages related to item #{pages.first["Filename"]}
        had differing information for #{field}:
        #{data}
      WARNING
      puts warning.yellow
      data.first
    end
  end

  # CSV has an entry for each particular page image, although the metadata
  # itself needs to be groups of them for example, id 1 and id 2 for the front
  # and back of a postcard need to be indexed as id 1 with metadata from both
  # (but only the first image), or combined into the HTML view
  def reconstitute_items
    # will be a hash of arrays, the first object in the array being the "first" page
    items = {}
    @csv.each do |row|
      next if row.header_row?
      id = row["Filename"]
      rel = row["Relation#1"]
      # if an item has no relation, add it as is
      # if an item has a relation which doesn't exist, consider this item the first page
      # if an item has a relation which already exists, add to that relation
      if present?(rel) && items.key?(rel)
        items[rel] << row
      else
        items[id] = [row]
      end
    end
    items
  end

  # we're assuming id represents the first page in a series
  def item_to_es(id, pages)
    doc = {}

    doc["id"] = id.gsub(".jpg", "")
    doc["category"] = "Images"
    doc["collection"] = @options["collection"]
    doc["collection_desc"] = @options["collection_desc"] || @options["collection"]
    # doc["contributor"]
    # TODO needs to be a nested field
    # doc["creator"] = data_from_pages(pages, "Artist/Creator#1", combine: true)
    doc["data_type"] = "csv"
    # TODO dates are NOT standardized so we'll either need to do a lot of work on this
    # end, or we need to fix this in luna
    # doc["date"]
    doc["date_display"] = data_from_pages(pages, "Date#1", combine: false)
    doc["description"] = data_from_pages(pages, "Description#1", combine: true).join(" ")
    # TODO since many of these have recto / verso in them, things could get confusing
    doc["format"] = data_from_pages(pages, "Format#1", combine: true)
    doc["identifier"] = doc["id"]
    # id is already a jpg for the first item
    doc["image_id"] = id
    # doc["keywords"]
    # TODO only eng or N/A, should these be altered to be more useful?
    # doc["language"]
    # doc["languages"]
    doc["medium"] = data_from_pages(pages, "Format#1", combine: true)
    people = [
      "Subject#1",
      "Subject#1$1",
      "Subject#1$2",
      "Subject#1$3",
      "Subject#1$4",
      "Subject#1$5",
      "Subject#1$6",
      "Subject#1$7",
    ]
    # multivalued keyword
    doc["people"] = people.map { |p| data_from_pages(pages, p, combine: true) }.flatten.uniq
    # no role or id for person nested object
    doc["person"] = doc["people"].map { |p| { "name" => p } }
    doc["places"] = data_from_pages(pages, "Coverage#1", combine: false)
    # doc["publisher"]
    # doc["recipient"]
    # doc["rights"]
    # doc["rights_holder"]
    # doc["rights_uri"]
    doc["source"] = data_from_pages(pages, "Source#1", combine: false)
    # doc["subjects"]
    # TODO problem with recto verso for this as well, don't want this multivalued, I suspect?
    doc["subcategory"] = data_from_pages(pages, "Format#1", combine: true).join(" ")
    doc["text"] = data_from_pages(pages, "Description#1", combine: true).join(" ")
    # doc["title"] = present?(row["Title#1"]) ? row["Title#1"] : "No Title"
    title = data_from_pages(pages, "Title#1", combine: false)
    doc["title"] = present?(title) ? title : "No Title"
    # TODO sort title?
    # doc["title_sort"]
    # doc["topics"]
    # doc["uri"]
    # filename in uri_data is coming from the filename of the CSV file, NOT the "Filename" column
    doc["uri_data"] = "#{@options["data_base"]}/data/#{@options["collection"]}/csv/#{filename}"
    doc["uri_html"] = "#{@options["data_base"]}/data/#{@options["collection"]}/output/#{@options["environment"]}/html/#{id}.html"
    # doc["works"]
    doc
  end


  # overriding in order so that "rows" of the csv are no longer the primary unit,
  # but rather "items" created in reconstitute_items
  def transform_es
    puts "transforming #{self.filename}"
    es_doc = []
    headers = @csv.headers
    items = reconstitute_items
    puts "Created #{items.length} items from #{@csv.length-1} rows in the CSV".green
    items.each do |id, pages|
      es_doc << item_to_es(id, pages)
    end
    if @options["output"]
      filepath = "#{@out_es}/#{self.filename(false)}.json"
      File.open(filepath, "w") { |f| f.write(pretty_json(es_doc)) }
    end
    es_doc
  end

end
