class TeiToEs

  ################
  #    XPATHS    #
  ################

  # in the below example, the xpath for "person" is altered
  def override_xpaths
    xpaths = {}
    xpaths["contributors"] = [
      "/TEI/teiHeader/fileDesc/titleStmt/principal",
      "/TEI/teiHeader/fileDesc/titleStmt/respStmt/name"
    ]
    xpaths["date_display"] = "/TEI/teiHeader/fileDesc/sourceDesc/bibl/date"
    xpaths["person"] = "//persName"
    xpaths["places"] = "//placeName"
    xpaths["publisher"] = "/TEI/teiHeader/fileDesc/publicationStmt/publisher"
    xpaths["recipient"] = "/TEI/teiHeader/profileDesc/correspDesc/correspAction[@type='deliveredTo']/persName"
    xpaths["source"] = "/TEI/teiHeader/fileDesc/sourceDesc/mxDesc[1]/msIdentifier/repository"
    xpaths["subcategory"] = "/TEI/text/body/div1[1]/@type"
    xpaths["text_en"] = "/TEI/text/body/div1[@lang='en']"
    xpaths["text_es"] = "/TEI/text/body/div1[@lang='es']"
    xpaths["titles"] = {
      "en" => "/TEI/teiHeader/fileDesc/titleStmt/title[@type='main'][@lang='en'][1]",
      "es" => "/TEI/teiHeader/fileDesc/titleStmt/title[@type='main'][@lang='es'][1]"
    }
    xpaths
  end

  #################
  #    GENERAL    #
  #################

  def build_person_obj(personXml)
    xmlid = personXml["id"]
    # collect the parts of the person's name
    personography_name = @personography
                          .xpath("//person[@id='#{xmlid}']/persName[@type='facet']")
                          .text
    display_name = personography_name.empty? ? "[unknown]" : personography_name
    {
      "id" => xmlid,
      "name" => Datura::Helpers.normalize_space(display_name),
      "role" => ""
    }
  end

  def read_file(path)
    CommonXml.create_xml_object("#{@options["collection_dir"]}/#{path}")
  end

  # do something before pulling fields
  def preprocessing
    # read additional files, alter the @xml, add data structures, etc
    @personography = read_file "source/authority/shanahan_listperson.xml"
  end

  # do something after pulling the fields
  def postprocessing
    # change the resulting @json object here
  end

  # Add more fields
  #  make sure they follow the custom field naming conventions
  #  *_d, *_i, *_k, *_t
  def assemble_collection_specific
    @json["text_t_en"] = text_en
    @json["text_t_es"] = text_es
    # no harm in populating these fields but we aren't using them currently
    # in the rails application
    @json["title_es_k"] = title_es
    @json["title_sort_es_k"] = title_sort_es
  end

  ################
  #    FIELDS    #
  ################

  # Overrides of default behavior
  # Please see docs/tei_to_es.rb for complete instructions and examples

  def category
    category = get_text(@xpaths["category"])
    category.length > 0 ? category.capitalize : "Writing"
  end

  def format
    matched_format = nil
    # iterate through all the formats until the first one matches
    @xpaths["formats"].each do |type, xpath|
      text = get_text(xpath)
      matched_format = type.capitalize if text && text.length > 0
    end
    matched_format
  end

  def language
    lang = get_text(@xpaths["language"])
    # don't send anything if there's no language
    lang.empty? ? nil : lang
  end

  def languages
    get_list(@xpaths["languages"])
  end

  def person
    list = []
    people = @xml.xpath(@xpaths["person"])
    people.each do |p|
      person = build_person_obj(p)
      # get parent element to determine the role
      parent_type = p.parent["type"]
      if parent_type
        # TODO check if these are the terms we want to use (Cather uses "addressee")
        role = "recipient" if parent_type == "deliveredTo"
        role = "creator" if parent_type == "sentBy"
        person["role"] = role
      end
      list << person
    end
    return list.uniq
  end

  # TODO rights, rights_uri, and rights_holder?
  def rights
    # TODO
  end

  def rights_holder
    "Elizabeth Jane and Steve Shanahan of Davey, NE"
  end

  def source
    rights_holder
  end

  def subcategory
    subcategory = get_text(@xpaths["subcategory"])
    subcategory == "note" ? "Document" : subcategory.capitalize
  end

  def text_en
    get_text(@xpaths["text_en"])
  end

  def text_es
    get_text(@xpaths["text_es"])
  end

  # title is english since API is in english
  def title
    title_label = get_text(@xpaths["titles"]["en"])
    # default to spanish title if there isn't an english one
    title_label ? title_label : get_text(@xpaths["titles"]["es"])
  end

  def title_es
    title_label = get_text(@xpaths["titles"]["es"])
    # default to an english title if there isn't anything for spanish
    title_label ? title_label : get_text(@xpaths["titles"]["en"])
  end

  # title sort is english since API is in english
  def title_sort
    Datura::Helpers.normalize_name(title)
  end

  def title_sort_es
    # put in lower case and remove some starting words
    down = title_es.downcase
    down.sub(/^el |^la |^los |^las /, "")
  end

  def uri
    File.join(@options["site_url"], @id)
  end

end
