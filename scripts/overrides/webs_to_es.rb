class WebsToEs < XmlToEs

  def override_xpaths
    {
      "text" => "//div",
      "text_en" => "//div[@lang='en']",
      "text_es" => "//div[@lang='es']",
      # look for more specific heading for title first
      "title_en" => "//div[@lang='en']/h3|//div[@lang='en']/h2",
      "title_es" => "//div[@lang='es']/h3|//div[@lang='es']/h2"
    }
  end

  def assemble_collection_specific
  #   @json["fieldname_k"] = some_value_or_method
    @json["text_t_en"] = text_en
    @json["text_t_es"] = text_es
  end

  def category
    "secondary_source"
  end

  def creator
    # TODO this may not always be true so we will need a way to check this
    { "name" => "Isabel Velázquez", "role" => "author" }
  end

  def date(before=true)
    CommonXml.date_standardize("2019", before)
  end

  def date_display
    "2019"
  end

  def languages
    # right now the two languages are equally represented
    # although we may want to consider the original language to be spanish
    ["es", "en"]
  end

  def subcategory
    # use the id to determine which part of the site this is from
    @id.split("_").first
  end

  def text_en
    get_text(@xpaths["text_en"])
  end

  def text_es
    get_text(@xpaths["text_es"])
  end

  def title
    section = subcategory.capitalize
    es = get_text(@xpaths["title_es"])
    en = get_text(@xpaths["title_en"])

    section += " #{es}" if es
    section += " (#{en})" if en && !en.empty?
    section
  end

  def uri
    # TODO this will always be the spanish version so we
    # shouldn't link to this via the family letters search results
    File.join(@options["site_url"], @id.gsub("_", "/"))
  end

end
