class WebsToEs < XmlToEs

  def override_xpaths
    {
      "text" => "//div",
      "text_en" => "//div[@lang='en']",
      "text_es" => "//div[@lang='es']",
      # look for more specific heading for title first
      "title_en" => "//div[@lang='en']/h1",
      "title_es" => "//div[@lang='es']/h1"
    }
  end

  def assemble_collection_specific
  #   @json["fieldname_k"] = some_value_or_method
    @json["text_t_en"] = text_en
    @json["text_t_es"] = text_es
  end

  def category
    "Secondary Source"
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

  def language
    # because this site defaults to spanish, consider the original always spanish
    "es"
  end

  def languages
    # right now the two languages are equally represented
    # although we may want to consider the original language to be spanish
    ["es", "en"]
  end

  def subcategory
    # use the id to determine which part of the site this is from
    @id.split("_").first.capitalize
  end

  # TODO what do we want to do for the "text" field in the API?
  # should it just be text_en ?
  def text
    [text_en, text_es].join(" ")
  end

  def text_en
    get_text(@xpaths["text_en"])
  end

  def text_es
    get_text(@xpaths["text_es"])
  end

  def title
    es = get_text(@xpaths["title_es"])
    en = get_text(@xpaths["title_en"])

    if es.empty?
      en
    else
      en.empty? ? es : "#{es} (#{en})"
    end
  end

  def uri
    # the ids are structured like the url
    # teach_lesson05 -> teach/lesson05
    # so long as all of the webscraped paths are only
    # nested one deep, the below should work
    # otherwise we need to revisit this and subcategory
    subcat, underscore, final_url_piece = @id.partition("_")
    File.join(@options["site_url"], subcat, final_url_piece)
  end

  def uri_data
    uri
  end

  def uri_html
    uri
  end

end
