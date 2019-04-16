class FileCsv

  def build_html_from_csv
    items = reconstitute_items
    items.each do |id, pages|
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.div(class: "main_content") {
        xml.div(class: "image_display")
        xml.h4(data_from_pages(pages, "Title#1", combine: false))
        pages.each do |page|
          xml.div(class: "image_item_display") {
            xml.p(page["Description#1"])
            xml.img(
              src: "#{@options["media_base"]}/iiif/2/#{@options["collection"]}%2F#{page["Filename"]}/full/!800,800/0/default.jpg",
              class: "display"
            )
          }
        end
        }
      end
      write_html_to_file(builder, id)
    end
  end

  # returns the data from either the first page or combines into array of values
  # flags any discrepancies if they are not to be combined
  # combine: false returns a string (and potentially a warning)
  # combine: true returns an array for flexibility of how it is treated on the other end
  def data_from_pages(pages, field, combine: false)
    data = pages.map { |p| CommonXml.normalize_space(p[field]) if present?(p[field]) }
    data = data.compact.uniq
    if combine
      # returns an array if combine is requested
      data
    else
      # return a string if combine was not requested
      if data.length > 1
        warning = <<-WARNING
          Pages related to item #{pages.first["Filename"]}
          had differing information for #{field}:
          #{data}
        WARNING
        puts warning.yellow
      end
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
      id = row["Filename"].gsub(".jpg", "")
      rel = row["Relation#1"].gsub(".jpg", "")
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

    doc["id"] = id
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
    formats = data_from_pages(pages, "Format#1", combine: true)
    # need to remove (recto) / verso type portions from the format
    formats = formats.map { |f| f[/(\w*) \(\w*\)/, 1] }.uniq
    doc["format"] = formats.length > 1 ? formats : formats.first
    doc["identifier"] = doc["id"]
    # add jpg to the id, since that was removed in a previous step
    # and we only want the image for the very first page involved
    doc["image_id"] = "#{id}.jpg"
    # doc["keywords"]
    # TODO only eng or N/A, should these be altered to be more useful?
    # doc["language"]
    # doc["languages"]
    doc["medium"] = doc["format"]
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
    # NOTE this should not be multivalued
    doc["subcategory"] = doc["format"].class == Array ? doc["format"].first : doc["format"]
    # doc["title"] = present?(row["Title#1"]) ? row["Title#1"] : "No Title"
    title = data_from_pages(pages, "Title#1", combine: false)
    doc["title"] = present?(title) ? title : "No Title"
    # TODO sort title?
    # doc["title_sort"]
    # doc["topics"]

    doc["text"] = data_from_pages(pages, "Description#1", combine: true).join(" ")
    doc["text"] += doc["title"] if doc["title"]
    doc["text"] += doc["date_display"] if doc["date_display"]
    doc["text"] += doc["people"].join(" ") if doc["people"]
    # TODO the majority of thse are in English but will they be translated into spanish??
    doc["text_t_en"] = doc["text"]

    # doc["uri"]
    # filename in uri_data is coming from the filename of the CSV file, NOT the "Filename" column
    doc["uri_data"] = "#{@options["data_base"]}/data/#{@options["collection"]}/csv/#{self.filename}"
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
