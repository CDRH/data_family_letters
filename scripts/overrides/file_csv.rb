class FileCsv

  def build_html_from_csv
    items = reconstitute_items
    items.each do |id, pages|
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.div(class: "main_content") {
        xml.div(class: "image_display")
        xml.h4(data_from_pages(pages, "Title#1", combine: false))
        pages.each do |page|
          image_name = page["Filename"].include?(".jpg") ? page["Filename"] : "#{page["Filename"]}.jpg"
          xml.div(class: "image_item_display") {
            xml.p(page["Description#1"]) if page["Description#1"]
            xml.p(page["Card Text"]) if page["Card Text"]
            xml.p(page["Written Text"]) if page["Written Text"]
            xml.img(
              src: "#{@options["media_base"]}/iiif/2/#{@options["collection"]}%2F#{image_name}/full/!800,800/0/default.jpg",
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
  # combine: false returns a string from the FIRST page only (and potentially a warning)
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
  # itself needs to be groups of them for example, filename 1 & 2 are front
  # and back of a postcard, grouped by the Identifier column
  # - need to be index as one item in API
  # - will be combined in the HTML view
  def reconstitute_items
    items = {}
    groups = @csv.group_by { |r| r["Identifier"] }
    groups.each do |group, rows|
      # skip header row
      next if group == "Identifier"

      id = rows.first["Filename"].sub(".jpg", "")
      items[id] = []
      rows.each do |row|
        items[id] << row
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
    first_date = data_from_pages(pages, "Date#1", combine: false)
    standard_date = standardize_date(first_date)
    doc["date"] = standard_date
    doc["date_not_before"] = standard_date
    doc["date_display"] = data_from_pages(pages, "Date#1", combine: false)
    # doc["date_not_after"]

    # description fields
    desc = data_from_pages(pages, "Description#1", combine: true).join(" ")
    text_written = data_from_pages(pages, "Written Text", combine: true).join(" ")
    text_card = data_from_pages(pages, "Card Text", combine: true).join(" ")
    doc["description"] = [ desc, text_written, text_card ].flatten.join(" ")
    formats = data_from_pages(pages, "Format#1", combine: true)
    # need to remove (recto) / verso type portions from the format
    formats = formats
                .map { |f| f[/(.*) ?(?:\((?:front|recto|verso|back\)))?/, 1] }
                .map(&:strip)
                .map(&:capitalize)
                .uniq
    doc["format"] = formats.length > 1 ? formats : [ formats.first ]
    doc["identifier"] = doc["id"]
    # add jpg to the id, since that was removed in a previous step
    # and we only want the image for the very first page involved
    doc["image_id"] = "#{id}.jpg"
    # doc["keywords"]
    # because there aren't languages associated with these items yet
    # leaving blank so that they don't even appear as "no label" on the site
    # doc["language"] = "n/a"
    # doc["languages"] = [ "unknown" ]

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
    recipient = data_from_pages(pages, "Subject#1", combine: false)
    doc["recipient"] = [ { "name" => recipient } ] if recipient
    # doc["rights"]
    # doc["rights_holder"]
    # doc["rights_uri"]
    doc["source"] = data_from_pages(pages, "Source#1", combine: false)
    # doc["subjects"]
    # NOTE this should not be multivalued
    # subcategory for documents should just be documents
    if self.filename(false) == "documents"
      doc["subcategory"] = "Document"
    else
      f = doc["format"].class == Array ? doc["format"].first : doc["format"]
      doc["subcategory"] = f
    end
    # doc["title"] = present?(row["Title#1"]) ? row["Title#1"] : "No Title"
    title = data_from_pages(pages, "Title#1", combine: false)
    # currently title likely english, okay because the API is in English
    doc["title"] = present?(title) ? title : "No Title"
    doc["title_sort"] = CommonXml.normalize_name(doc["title"])
    # there is no spanish translation so for now we are just duplicating fields
    doc["title_es_k"] = doc["title"]
    doc["title_sort_es_k"] = doc["title_sort"]
    # doc["topics"]

    # text field combining
    people = doc["people"] ? doc["people"].join(" ") : ""
    doc["text"] = [ doc["description"], doc["title"], doc["date_display"], people].flatten.join(" ")
    # TODO the majority of these are in English but will they be translated into spanish??
    doc["text_t_en"] = doc["text"]

    # doc["uri"]
    # filename in uri_data is coming from the filename of the CSV file, NOT the "Filename" column
    doc["uri_data"] = "#{@options["data_base"]}/data/#{@options["collection"]}/csv/#{self.filename}"
    doc["uri_html"] = "#{@options["data_base"]}/data/#{@options["collection"]}/output/#{@options["environment"]}/html/#{id}.html"
    # doc["works"]
    doc
  end

  def standardize_date(dirty)
    # Note: so far we are ONLY populating the date and date_not_before
    # from the CSV because of how dates are recorded, although in some
    # cases there ARE ending dates which are not being caught
    if dirty
      # removes (circa) and whitespace from dates
      scrubbed = dirty.gsub(/[A-Za-z\(\) ]/, "")
      # when there is a range (1940-1945) currently ignoring second half
      if scrubbed[/\d{4}-\d{4}/]
        scrubbed = scrubbed[/^\d{4}/]
      end
      CommonXml.date_standardize(scrubbed)
    end
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
