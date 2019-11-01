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
    @json["title_es_k"] = title_es_k
    @json["title_sort_es_k"] = title_sort_es_k
  end

  def category
    "Site Section"
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
    "Site Section"
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
    en = get_text(@xpaths["title_en"])
    es = get_text(@xpaths["title_es"])

    en.empty? ? es : en
  end

  def title_sort
    CommonXml.normalize_name(title)
  end

  def title_es_k
    es = get_text(@xpaths["title_es"])
    en = get_text(@xpaths["title_en"])

    es.empty? ? en : es
  end

  def title_sort_es_k
    down = title_es_k.downcase
    down.sub(/^el |^la |^los |^las /, "")
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
