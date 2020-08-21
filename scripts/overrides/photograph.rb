class Photograph

  def initialize(item)
    @item = item
  end

  def draw_point
    if @item["spatial"]
      s = @item["spatial"].first
      {
        "type" => "Point",
        "coordinates" => [
          s["coordinates"]["lon"],
          s["coordinates"]["lat"]
        ]
      }
    end
  end

  def feature
    {
      "type" => "Feature",
      "properties" => properties,
      "geometry" => draw_point
    }
  end

  def location
    if @item["spatial"]
      s = @item["spatial"].first
      s["title"]
    end
  end

  def properties
    {
      "identifier" => @item["identifier"],
      "title" => @item["title"],
      "title_es" => @item["title_es_k"],
      "date" => @item["date"],
      "date_display" => @item["date_display"],
      "image_id" => @item["image_id"],
      "location" => location
    }
  end

end
