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
    display_name = @personography.xpath("//person[@id='#{xmlid}']/persName[@type='display']").text
    {
      "id" => xmlid,
      "name" => CommonXml.normalize_space(display_name),
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
    @json["title_es_k"] = title_es
    @json["title_sort_es_k"] = title_sort_es
  end

  ################
  #    FIELDS    #
  ################

  # Overrides of default behavior
  # Please see docs/tei_to_es.rb for complete instructions and examples

  # TODO should we change cather so that writings is undercase?
  def category
    category = get_text(@xpaths["category"])
    category.length > 0 ? category : "Writings"
  end

  def recipient
    list = []
    eles = @xml.xpath(@xpaths["recipient"])
    eles.each do |p|
      recip = build_person_obj(p)
      recip["role"] = "recipient"
      list << recip
    end
    list
  end

  # TODO should we change cather so that Letters is undercase? plural or singular?
  def subcategory
    subcategory = get_text(@xpaths["subcategory"])
    subcategory = subcategory == "letter" ? "Letters" : subcategory
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

  def text_en
    get_text(@xpaths["text_en"], false)
  end

  def text_es
    get_text(@xpaths["text_es"], false)
  end

  # title is english since API is in english
  def title
    get_text(@xpaths["titles"]["en"])
  end

  def title_es
    get_text(@xpaths["titles"]["es"])
  end

  # title sort is english since API is in english
  def title_sort
    t = title
    CommonXml.normalize_name(t)
  end

  def title_sort_es
    t = title_es
    # put in lower case and remove some starting words
    down = t.downcase
    down.gsub(/^el |^la |^los |^las /, "")
  end

  def uri
    "https://familyletters.unl.edu/#{@id}"
  end

end
